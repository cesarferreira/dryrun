require 'optparse'
require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/version'
require 'dryrun/android_project'

module DryRun
  class MainApp
    def initialize(arguments)
      create_options_parser
      @url = ['-h', '--help', '-v', '--version'].include?(arguments.first) ? nil : arguments.shift
      @app_path = nil
      @custom_module = nil
      @opt_parser.parse!(arguments)

      unless @url
        puts @opt_parser.help
        exit
      end
    end

    def create_options_parser
      @opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: dryrun GITHUB_URL [OPTIONS]"
        opts.separator  ''
        opts.separator  "Options"

        opts.on('-m MODULE_NAME', '--module MODULE_NAME', 'Custom module to run') do |custom_module|
          @custom_module = custom_module
        end
        opts.on('-p PATH', '--path PATH', 'Custom path to android project') do |app_path|
          @app_path = app_path
        end
        opts.on('-h', '--help', 'Displays help') do
          puts opts.help
          exit
        end
        opts.on('-v', '--version', 'Displays version') do
          puts DryRun::VERSION
          exit
        end
      end
    end

    def android_home_is_defined
      sdk = `echo $ANDROID_HOME`.gsub("\n",'')
      !sdk.empty?
    end

    def call
      unless android_home_is_defined
        puts "\nWARNING: your #{'$ANDROID_HOME'.yellow} is not defined\n"
        puts "\nhint: in your #{'~/.bashrc'.yellow} add:\n  #{"export ANDROID_HOME=\"/Users/cesarferreira/Library/Android/sdk/\"".yellow}"
        puts "\nNow type #{'source ~/.bashrc'.yellow}\n\n"
        exit 1
      end

      github = Github.new(@url)

      unless github.is_valid
        puts "#{@url.red} is not a valid github @url"
        exit 1
      end

      # clone the repository
      repository_path = github.clone

      android_project = AndroidProject.new(repository_path, @app_path, @custom_module)

      # is a valid android project?
      unless android_project.is_valid
        puts "#{@url.red} is not a valid android project"
        exit 1
      end

      puts "Using custom app folder: #{@app_path.green}" if @app_path
      puts "Using custom module: #{@custom_module.green}" if @custom_module

      # clean and install the apk
      android_project.install

      puts "\n> If you want to remove the app you just installed, execute:\n#{android_project.get_uninstall_command.yellow}\n\n"
    end
  end
end
