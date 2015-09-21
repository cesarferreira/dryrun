require 'nokogiri'
require 'fileutils'
require 'tempfile'

module DryRun
  class AndroidProject
    def initialize(path, custom_app_path, custom_module)
      @custom_app_path = custom_app_path
      @custom_module = custom_module
      @base_path = path
      @settings_gradle_path = settings_gradle_file

      check_custom_app_path

      @modules = find_modules
    end

    def check_custom_app_path
      return unless @custom_app_path

      full_custom_path = File.join(@base_path, @custom_app_path)
      settings_path = settings_gradle_file(full_custom_path)
      return unless is_valid(settings_path)

      @settings_gradle_path = settings_path
      @base_path = full_custom_path
    end

    def remove_local_properties
      Dir.chdir @base_path
      file_name = 'local.properties'

      File.delete(file_name) if File.exist?(file_name)

      system("touch #{file_name}")
    end

    def remove_application_id
      # Open temporary file
      tmp = Tempfile.new("extract")

      file = "#{@path_to_sample}/build.gradle"

      # Write good lines to temporary file
      open(file, 'r').each { |l| tmp << l unless l.include? 'applicationId' }
      tmp.close

      # Move temp file to origin
      FileUtils.mv(tmp.path, file)
    end

    def settings_gradle_file(path = @base_path)
      File.join(path, 'settings.gradle')
    end

    def is_valid(settings_path = @settings_gradle_path)
      File.exist?(settings_path)
    end

    def find_modules
      return [] unless is_valid

      content = File.open(@settings_gradle_path, "rb").read
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

      builder = "gradle"

      if File.exist?('gradlew')
        system('chmod +x gradlew')

        builder = 'sh gradlew'
      end

      # Generate the gradle/ folder
      system('gradle wrap') if File.exist?('gradlew') and !is_gradle_wrapped

      remove_application_id
      remove_local_properties

      if @custom_module
        system("#{builder} clean :#{@custom_module}:installDebug")
      else
        system("#{builder} clean installDebug")
      end

      clear_app_data

      puts "Installing #{@package.green}...\n"
      puts "executing: #{execute_line.green}\n\n"

      system(execute_line)

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
        @modules.each do |child|
          full_path = File.join(@base_path, child.first)
          @path_to_sample = full_path

          execution_line_command = get_execution_line_command(full_path)
          return full_path, execution_line_command if execution_line_command
        end
      end
      [false, false]
    end

    def get_clear_app_command
      "adb shell pm clear #{@package}"
    end

    def get_uninstall_command
      "adb uninstall #{@package}"
    end

    def clear_app_data
      system(get_clear_app_command)
    end

    def uninstall_application
      system(get_uninstall_command) # > /dev/null 2>&1")
    end

    def get_execution_line_command(path_to_sample)
      path_to_manifest = File.join(path_to_sample, 'src/main/AndroidManifest.xml')

      if !File.exist?(path_to_manifest)
        return false
      end

      f = File.open(path_to_manifest)
      doc = Nokogiri::XML(f)

      @package = get_package(doc)
      @launcher_activity = get_launcher_activity(doc)

      if !@launcher_activity
        return false
      end

      f.close

      "adb shell am start -n \"#{get_launchable_activity}\" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
    end

    def get_launchable_activity
      full_path_to_launcher = "#{@package}#{@launcher_activity.gsub(@package,'')}"
      "#{@package}/#{full_path_to_launcher}"
    end

    def get_package(doc)
       doc.xpath("//manifest").attr('package').value
    end

    def get_launcher_activity(doc)
      activities = doc.css('activity')
      activities.each do |child|
        intent_filter = child.css('intent-filter')
        if intent_filter != nil and intent_filter.length != 0
          return child.attr('android:name')
        end
      end
      false
    end
  end
end
