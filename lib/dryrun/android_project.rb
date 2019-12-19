require 'oga'
require 'fileutils'
require 'tempfile'
require 'find'
require_relative 'dryrun_utils'
require_relative 'manifest_parser'
require_relative 'gradle_adapter'

module Dryrun
  class AndroidProject
    def initialize(path, custom_app_path, custom_module, flavour, device)
      @custom_app_path = custom_app_path
      @custom_module = custom_module
      @base_path = @custom_app_path ? File.join(path, @custom_app_path) : path
      @flavour = flavour
      @device = device
      @gradle_file_extension = gradle_file_extension
      @settings_gradle_path = settings_gradle_file
      @main_gradle_file = main_gradle_file

      check_custom_app_path

      @modules = find_modules
    end

    def gradle_file_extension
      gradle_file = File.join(@base_path, 'settings.gradle.kts')
      if (File.exist?(gradle_file))
        return ".gradle.kts"
      end
      ".gradle"
    end

    def check_custom_app_path
      return unless @custom_app_path

      full_custom_path = @base_path
      settings_path = settings_gradle_file(full_custom_path)
      main_gradle_path = main_gradle_file(full_custom_path)
      return unless valid?(main_gradle_path)

      @settings_gradle_path = settings_path
      @main_gradle_file = main_gradle_file

      @base_path = full_custom_path
    end

    def remove_local_properties
      Dir.chdir @base_path
      file_name = 'local.properties'

      File.delete(file_name) if File.exist?(file_name)

      DryrunUtils.execute("touch #{file_name}") unless Gem.win_platform?
    end

    def remove_application_id
      # Open temporary file
      tmp = Tempfile.new('extract')

      file = "#{@path_to_sample}/build#{@gradle_file_extension}"

      # Write good lines to temporary file
      File.open(file, 'r') do |f|
        f.each do |l|
          tmp << l unless l.include? 'applicationId'
        end
      end
      tmp.close

      # Move temp file to origin
      FileUtils.mv(tmp.path, file)
    end

    def settings_gradle_file(path = @base_path)
      File.join(path, "settings#{@gradle_file_extension}")
    end

    def main_gradle_file(path = @base_path)
      File.join(path, "build#{@gradle_file_extension}")
    end

    def valid?(main_gradle_file = @main_gradle_file)
      File.exist?(main_gradle_file) &&
          File.exist?(@settings_gradle_path)
    end

    def find_modules
      return [] unless valid?

      content = File.open(@settings_gradle_path, 'rb').read
      
      content = content.split(/\n/).delete_if { |x| !x.start_with?("include")}.join("\n")
      modules = content.scan(/'([^']*)'/) + content.scan(/\"([^"]*)\"/)
      
      modules.each {|replacement| replacement.first.tr!(':', '')}
    end

    def execute_command(command)
      Dir.chdir @base_path

      path = sample_project
      if path == false or !@launcher_activity
        puts "Couldn't open or there isnt any sample project, sorry!".red
        exit 1
      end

      builder = create_builder

      remove_application_id
      remove_local_properties

      command.run(builder, @package, @launcher_activity, @custom_module, @flavour, @device)
    end

    def gradle_wrapped?
      return false unless File.directory?('gradle/')

      File.exist?('gradle/wrapper/gradle-wrapper.properties') &&
          File.exist?('gradle/wrapper/gradle-wrapper.jar')
    end

    def sample_project
      if @custom_module && @modules.any? {|m| m.first == "#{@custom_module}"}
        @path_to_sample = File.join(@base_path, "#{@custom_module}")
        return @path_to_sample if parse_manifest(@path_to_sample)
      else
        @modules.each do |child|
          full_path = File.join(@base_path, child.first)
          @path_to_sample = full_path
          return full_path if parse_manifest(full_path)
        end
      end
      false
    end

    def uninstall_command
      "adb uninstall \"#{@package}\""
    end

    def uninstall_application
      DryrunUtils.run_adb("shell pm uninstall #{@package}")
    end

    def parse_manifest(path_to_sample)
      manifest_file = get_manifest(path_to_sample)

      return false if manifest_file.nil?

      manifest_parser = ManifestParser.new(manifest_file)
      @package = manifest_parser.package
      @launcher_activity = manifest_parser.launcher_activity
      manifest_file.close
      @launcher_activity && @package
    end

    def get_manifest(path_to_sample)
      default_path = File.join(path_to_sample, 'src/main/AndroidManifest.xml')

      if File.exist?(default_path)
        File.open(default_path)
      else
        puts path_to_sample
        Find.find(path_to_sample) do |path|
          return File.open(path) if path =~ /.*AndroidManifest.xml$/
        end
      end
    end

    def create_builder
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
      DryrunUtils.execute('gradle wrap') if File.exist?('gradlew') && !gradle_wrapped?
      GradleAdapter.new(builder)
    end
  end
end
