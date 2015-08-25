require 'nokogiri'
require 'fileutils'
require 'tempfile'

module DryRun

  class AndroidProject

    def initialize(path)
      @base_path = path
      @settings_gradle_path = settings_gradle
      @modules = find_modules
    end

    def remove_local_properties
      Dir.chdir @base_path
      file_name = 'local.properties'

      if File.exist?(file_name)
        File.remove(file_name)
      end
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

    def settings_gradle
      "#{@base_path}/settings.gradle"
    end

    def is_valid
      File.exist?(@settings_gradle_path)
    end

    def find_modules
      if self.is_valid
        content = File.open(@settings_gradle_path, "rb").read
        modules = content.scan(/'([^']*)'/)
        modules.each {|replacement| replacement.first.gsub!(':', '/')}
      else
        return []
      end
    end

    # ./gradlew clean installDebug
    def install

      Dir.chdir @base_path

      path, execute_line = self.sample_project

      if path == false and execute_line==false
        puts "Couldn't open, sorry!".red
        exit 1
      end

      builder = "gradle"

      if File.exist?('gradlew')
        system('chmod +x gradlew')

        builder = 'sh gradlew'
      end

      # Generate the gradle/ folder
      if File.exist?('gradlew') and !is_gradle_wrapped
        system('gradle wrap')
      end

      self.uninstall
      self.remove_application_id
      self.remove_local_properties

      system("#{builder} clean assembleDebug installDebug")

      puts "Installing #{@package.green}...\n"
      puts "executing: #{execute_line.green}\n\n"
      system(execute_line)

    end

    def is_gradle_wrapped

      if !File.directory?('gradle/')
        return false
      end

      File.exist?('gradle/wrapper/gradle-wrapper.properties') and File.exist?('gradle/wrapper/gradle-wrapper.jar')
    end

    def sample_project

      @modules.each do |child|
        full_path = "#{@base_path}/#{child.first}"
        @path_to_sample = full_path
        # binding.pry

        execute_line = get_execute_line("#{full_path}/src/main/AndroidManifest.xml")
        return full_path, execute_line if execute_line

      end
      return false, false
    end

    def get_uninstall_command
      "adb uninstall #{@package}"
    end

    def uninstall
      system("#{self.get_uninstall_command}") # > /dev/null 2>&1")
    end


    def get_execute_line(path_to_sample)

      if !File.exist?(path_to_sample)
        return false
      end

      f = File.open(path_to_sample)
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
