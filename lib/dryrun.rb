require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/android_project'

module DryRun

  class MainApp

    def self.is_ANDROID_HOME_defined
      return true
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

      # puts "\nLets work this one out: #{url.green}\n\n"

      # clone the repository
      clonable = github.clonable_url
      #puts "git clone #{clonable.yellow}.....\n\n"

      repository = github.clone

      Dir.chdir repository

      project = AndroidProject.new(repository)

      # is a valid android project?
      if !project.is_valid
        puts "#{url.red} is not a valid android project"
        exit 1
      end

      project.clean_install


      puts "\nOpened #{url.green}!\n"

    end
  end
end
