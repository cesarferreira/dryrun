require 'adb-sdklib'
require 'optparse'
require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/version'
require 'dryrun/android_project'
require "highline/import"
require 'openssl'

module DryRun
  class MainApp
    def initialize(arguments)
      outdated_verification
      @url = ['-h', '--help', '-v', '--version'].include?(arguments.first) ? nil : arguments.shift

      # defaults
      @app_path = nil
      @custom_module = nil
      @flavour = ''
      @tag = nil
      @branch = "master"

      # Parse Options
      arguments.push "-h" unless @url
      create_options_parser(arguments)
    end

    def create_options_parser(args)
      args.options do |opts|
        opts.banner = "Usage: dryrun GIT_URL [OPTIONS]"
        opts.separator  ''
        opts.separator  "Options"

        opts.on('-m MODULE_NAME', '--module MODULE_NAME', 'Custom module to run') do |custom_module|
          @custom_module = custom_module
        end

        opts.on('-b BRANCH_NAME', '--branch BRANCH_NAME', 'Checkout custom branch to run') do |branch|
          @branch = branch
        end

        opts.on('-f', '--flavour FLAVOUR', 'Custom flavour (e.g. dev, qa, prod)') do |flavour|
          @flavour = flavour.capitalize
        end

        opts.on('-p PATH', '--path PATH', 'Custom path to android project') do |app_path|
          @app_path = app_path
        end

        opts.on('-t TAG', '--tag TAG', 'Checkout tag/commit hash to clone (e.g. "v0.4.5", "6f7dd4b")') do |tag|
          @tag = tag
        end

        opts.on('-h', '--help', 'Displays help') do
          puts opts.help
          exit
        end

        opts.on('-v', '--version', 'Displays the version') do
          puts DryRun::VERSION
          exit
        end

        opts.parse!

      end
    end

    def outdated_verification
      is_up_to_date = DryrunUtils.is_up_to_date

      if is_up_to_date
        return
      end

      input = nil

      begin
        input = ask "\n#{'Your Dryrun version is outdated, want to update?'.yellow} #{'[Y/n]:'.white}"
      end while !['y', 'n', 's'].include?(input.downcase)

      if input.downcase.eql? 'y'
        DryrunUtils.execute('gem update dryrun')

      end

    end

    def pick_device()
      if !Gem.win_platform?
        sdk = `echo $ANDROID_HOME`.gsub("\n",'')
        sdk = sdk + "/platform-tools/adb";
      else
        sdk = `echo %ANDROID_HOME%`.gsub("\n",'')
        sdk = sdk + "/platform-tools/adb.exe"
      end

      puts "Searching for devices...".yellow
      adb = AdbSdkLib::Adb.new(sdk)
      devices = adb.devices;

      if devices.empty?
        puts "No devices attached, but I'll run anyway"
      end

      @device = nil

      if devices.size >= 2
        puts "Pick your device (1,2,3...):"

        devices.each_with_index.map {|key, index| puts "#{index.to_s.green} -  #{key} \n"}

        a = gets.chomp

        if a.match(/^\d+$/) && a.to_i <= (devices.length - 1) && a.to_i >= 0
          @device = devices.to_a.at((a.to_i))[1]
        else
          @device = devices.first
        end
      else
        @device = devices.first
      end

      puts "Picked #{@device.to_s.green}" if @device
    end


    def android_home_is_defined
      if !Gem.win_platform?
        sdk = `echo $ANDROID_HOME`.gsub("\n",'')
      else
        sdk = `echo %ANDROID_HOME%`.gsub("\n",'')
      end
      !sdk.empty?
    end

    def call
      unless android_home_is_defined
        puts "\nWARNING: your #{'$ANDROID_HOME'.yellow} is not defined\n"
        puts "\nhint: in your #{'~/.bashrc'.yellow} or #{'~/.bash_profile'.yellow}  add:\n  #{"export ANDROID_HOME=\"/Users/cesarferreira/Library/Android/sdk/\"".yellow}"
        puts "\nNow type #{'source ~/.bashrc'.yellow}\n\n"
        exit 1
      end

      @url = @url.split("?").first

      pick_device()

      github = Github.new(@url)

      unless github.is_valid
        puts "#{@url.red} is not a valid git @url"
        exit 1
      end

      # clone the repository
      repository_path = github.clone(@branch, @tag)

      android_project = AndroidProject.new(repository_path, @app_path, @custom_module, @flavour, @device)

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
