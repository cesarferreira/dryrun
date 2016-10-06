require 'oga'
require 'fileutils'
require 'tempfile'
require 'find'
require_relative 'dryrun_utils'

module Dryrun
  class AndroidProject
    def initialize(path, custom_app_path, custom_module, flavour, build_type, device)

      @custom_app_path = custom_app_path
      @custom_module = custom_module
      @base_path = @custom_app_path? File.join(path, @custom_app_path) : path
      @flavour = flavour
      @build_type = build_type
      @device = device
      @application_id = ''
      @root_module = ''

      @settings_gradle_path = settings_gradle_file
      @main_gradle_file = main_gradle_file

      check_custom_app_path

      @modules = find_modules
    end

    def check_custom_app_path
      return unless @custom_app_path

      full_custom_path = @base_path
      settings_path = settings_gradle_file(full_custom_path)
      main_gradle_path = main_gradle_file(full_custom_path)
      return unless is_valid(main_gradle_path)

      @settings_gradle_path = settings_path
      @main_gradle_file = main_gradle_file

      @base_path = full_custom_path
    end

    def extract_application_id
      # Open temporary file
      tmp = Tempfile.new('extract')

      file = "#{@path_to_sample}/build.gradle"

      # Write good lines to temporary file
      File.open(file, 'r') { |file|
        file.each do |l|
          if l.include? 'applicationId'
            @application_id = l.split(' ')[1].gsub('"', '')
            break
          end
        end
      }
      tmp.close
    end

    def remove_local_properties
      Dir.chdir @base_path
      file_name = 'local.properties'

      File.delete(file_name) if File.exist?(file_name)
      if !Gem.win_platform?
        DryrunUtils.execute("touch #{file_name}")
      end
    end

    def remove_application_id
      # Open temporary file
      tmp = Tempfile.new('extract')

      file = "#{@path_to_sample}/build.gradle"

      # Write good lines to temporary file
      File.open(file, 'r') do |file|
        file.each do |l|
          tmp << l unless l.include? 'applicationId'
        end
      end
      tmp.close

      # Move temp file to origin
      FileUtils.mv(tmp.path, file)
    end

    def settings_gradle_file(path = @base_path)
      File.join(path, 'settings.gradle')
    end

    def main_gradle_file(path = @base_path)
      File.join(path, 'build.gradle')
    end

    def is_valid(main_gradle_file = @main_gradle_file)
      File.exist?(main_gradle_file)
    end

    def find_modules
      return [] unless is_valid

      content = File.open(@settings_gradle_path, 'rb').read
      modules = content.scan(/'([^']*)'/)
      modules.each {|replacement| replacement.first.gsub!(':', '/')}
    end

    def install
      Dir.chdir @base_path

      path, execute_line = sample_project

      if path == false and execute_line == false
        puts "Couldn't open the sample project, sorry!".red
        exit 1
      end

      builder = 'gradle'

      if File.exist?('gradlew')
        if !Gem.win_platform?
          DryrunUtils.execute('chmod +x gradlew')
        else
          DryrunUtils.execute('icacls gradlew /T')
        end
        builder = './gradlew'
      end

      # Generate the gradle/ folder
      DryrunUtils.execute('gradle wrap') if File.exist?('gradlew') and !is_gradle_wrapped

      remove_local_properties

      root_module_builder = if @custom_module == nil
                              ''
                            else
                              ":#{@custom_module}:"
                            end

      pre_execute_builder = root_module_builder + "install#{@flavour || ''}#{@build_type || 'Debug'}"

      DryrunUtils.execute("#{builder} clean")
      DryrunUtils.execute("#{builder} #{pre_execute_builder}")

      if Dryrun::MainApp.getDevice != nil
        clear_app_data
        puts "Installing #{@package.green}...\n"
        puts "executing: #{execute_line.green}\n"

        DryrunUtils.run_adb("shell #{execute_line}")
      end
    end

    def is_gradle_wrapped
      return false if !File.directory?('gradle/')

      File.exist?('gradle/wrapper/gradle-wrapper.properties') and File.exist?('gradle/wrapper/gradle-wrapper.jar')
    end

    def sample_project
      if @custom_module && @modules.any? { |m| m.first == "/#{@custom_module}" }
        @path_to_sample = File.join(@base_path, "/#{@custom_module}")
        return @path_to_sample, get_execution_line_command(@path_to_sample)
      else

        @root_module = 'app'  if @modules.first.first.gsub('/','') == 'app'

        @modules.each do |child|
          full_path = File.join(@base_path, child.first)
          @path_to_sample = full_path

          execution_line_command = get_execution_line_command(full_path)
          return full_path, execution_line_command if execution_line_command
        end
      end
      [false, false]
    end

    def get_uninstall_command
     "adb uninstall \"#{@package}\""
   end

   def clear_app_data
     DryrunUtils.run_adb("shell pm clear #{@package}")
   end

   def uninstall_application
    DryrunUtils.run_adb("shell pm uninstall #{@package}")
  end

  def get_execution_line_command(path_to_sample)
    manifest_file = get_manifest(path_to_sample)

    if manifest_file.nil?
      return false
    end

    doc = Oga.parse_xml(manifest_file)

      extract_application_id

      @package = @application_id + '.' + @build_type.downcase
      @launcher_activity = get_launcher_activity(doc)

    if !@launcher_activity
      return false
    end

    manifest_file.close

    return "am start -n \"#{get_launchable_activity}\" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
  end

  def get_manifest(path_to_sample)
    default_path = File.join(path_to_sample, 'src/main/AndroidManifest.xml')
    if File.exist?(default_path)
      return File.open(default_path)
    else
      Find.find(path_to_sample) do |path|
        return File.open(path) if path =~ /.*AndroidManifest.xml$/
      end
    end
  end

  def get_launchable_activity
    full_path_to_launcher = "#{@package}#{@launcher_activity.gsub(@package,'')}"
    "#{@package}/#{full_path_to_launcher}"
  end

    def get_package(doc)
     doc.xpath('//manifest').attr('package').first.value
   end

 def get_launcher_activity(doc)
  activities = doc.css('activity')
  activities.each do |child|
    intent_filter = child.css('intent-filter')

      if intent_filter != nil and intent_filter.length != 0
        return child.attr('android:name').value
      end
    end
    false
  end
end
end
