require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/android_project'

module DryRun

  class MainApp

    def self.ANDROID_HOME_is_defined
      sdk = `echo $ANDROID_HOME`.gsub("\n",'')
      !sdk.empty?
    end


    def self.initialize(url)

      unless self.ANDROID_HOME_is_defined
        puts "\nWARNING: your #{'$ANDROID_HOME'.yellow} is not defined\n"
        puts "\nhint: in your #{'~/.bashrc'.yellow} add:\n  #{"export ANDROID_HOME=\"/Users/cesarferreira/Library/Android/sdk/\"".yellow}"
        puts "\nNow type #{'source ~/.bashrc'.yellow}\n\n"
        exit 1
      end

      github = Github.new(url)

      unless github.is_valid
        puts "#{url.red} is not a valid github url"
        exit 1
      end

      # clone the repository
      repository_path = github.clone

      android_project = AndroidProject.new(repository_path)

      # is a valid android project?
      unless android_project.is_valid
        puts "#{url.red} is not a valid android project"
        exit 1
      end

      # clean and install the apk
      android_project.install

      puts "\n> If you want to remove the app you just installed, execute:\n#{android_project.get_uninstall_command.yellow}\n\n"

    end
  end
end
