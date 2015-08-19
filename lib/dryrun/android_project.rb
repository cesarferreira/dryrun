require 'nokogiri'

module DryRun

  class AndroidProject

    def initialize(path)
      @base_path = path
      @settings_gradle_path = settings_gradle
      @modules = find_modules
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
    def clean_install

      path, execute_line = self.sample_project


      if path == false and execute_line==false
        puts "Couldn't open, sorry!".red
        return ''
      end

      Dir.chdir @base_path

      self.uninstall

      # clean assemble and install
      system("./gradlew clean assembleDebug installDebug")


      puts "Installing #{@package.green}...\n"
      puts "executing: #{execute_line}"
      system(execute_line)

    end

    def sample_project

      @modules.each do |child|
        full_path = "#{@base_path}#{child.first}"

        execute_line = get_execute_line("#{full_path}/src/main/AndroidManifest.xml")

        if execute_line
          puts "\nTHE SAMPLE IS HERE #{full_path.green}:\n"

          system("tree #{full_path}")

          return full_path, execute_line
        end

      end
      return false, false
    end

    def uninstall
      system("adb uninstall #{@package}")
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

      "adb shell am start -n #{@package}/#{@launcher_activity}"

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
