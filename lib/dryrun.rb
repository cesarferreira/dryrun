require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/android_project'
require 'dryrun/config'

module DryRun

  class MainApp

    def self.is_ANDROID_HOME_defined
      return !DryRun::Config.load.nil?
    end


    def self.initialize(url)

      if !is_ANDROID_HOME_defined
        # TODO missing warning
      end

      github = Github.new(url)

      if !github.is_valid
        puts "#{url.red} is not a valid github url"
        exit 1
      end

      # clone the repository
      clonable = github.clonable_url

      repository = github.clone

      Dir.chdir repository

      project = AndroidProject.new(repository)

      # is a valid android project?
      if !project.is_valid
        puts "#{url.red} is not a valid android project"
        exit 1
      end

      # clean and install the apk
      project.clean_install

      puts "\n> If you want to remove the app you just installed, execute:\n#{project.get_uninstall_command.yellow}\n\n"

    end
  end
end
