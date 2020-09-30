require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/version'
require 'dryrun/android_project'
require 'dryrun/install_application_command'
require 'dryrun/test_application_command'
require 'dryrun/device'
require 'highline/import'
require 'openssl'
require 'open3'
require 'optparse'

module Dryrun
  class MainApp
    def initialize(arguments)
      outdated_verification

      @url = %w(-h --help -v --version -w --wipe).include?(arguments.first) ? nil : arguments.shift

      # defaults
      @app_path = nil
      @custom_module = nil
      @flavour = ''
      @tag = nil
      @branch = 'master'
      @devices = []
      @cleanup = false
      @command = InstallApplicationCommand.new

      # Parse Options
      create_options_parser(arguments)
    end

    def create_options_parser(args)
      args.options do |opts|
        opts.banner = 'Usage: dryrun GIT_URL [OPTIONS]'
        opts.separator ''
        opts.separator 'Options'

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

        opts.on('-c', '--cleanup', 'Clean the temporary folder before cloning the project') do
          @cleanup = true
        end

        opts.on('-w', '--wipe', 'Wipe the temporary dryrun folder') do
          wipe_temporary_folder
        end

        opts.on('-h', '--help', 'Displays help') do
          puts opts.help
          exit
        end

        opts.on('-v', '--version', 'Displays the version') do
          puts Dryrun::VERSION
          exit
        end

        opts.on('-a', '--android-test', 'Execute android tests') do
          @command = TestApplicationCommand.new
        end

        opts.parse!
      end
    end

    def outdated_verification
      return if DryrunUtils.up_to_date

      input = nil

      begin
        input = ask "\n#{'Your Dryrun version is outdated, want to update?'.yellow} #{'[Y/n]:'.white}"
      end until %w(y n s).include?(input.downcase)

      DryrunUtils.execute('gem update dryrun') if input.casecmp('y') == 0
    end

    def pick_device
      @device = nil

      if !Gem.win_platform?
        @sdk = `echo $ANDROID_SDK_ROOT`.delete("\n")
      else
        @sdk = `echo %ANDROID_SDK_ROOT%`.delete("\n")
      end

      @sdk = 'adb' if @sdk.empty?

      $sdk = @sdk

      puts 'Searching for devices...'.yellow

      @devices = DryrunUtils.run_adb('devices')

      # if @devices.nil? || @devices.empty?
      #   puts 'Killing adb, there might be an issue with it...'
      #   DryrunUtils.run_adb('kill-server')
      #   @devices = DryrunUtils.run_adb('devices')
      # end

      puts 'No devices attached, but I\'ll run anyway' if @devices.empty?

      if @devices.size >= 2
        puts 'Pick your device (1,2,3...):'

        @devices.each_with_index.map {|key, index| puts "#{index.to_s.green} -  #{key.name} \n"}

        input = gets.chomp

        @device = if input.match(/^\d+$/) && input.to_i <= (@devices.length - 1) && input.to_i >= 0
                    @devices[input.to_i]
                  else
                    @devices.first
                  end
      else
        @device = @devices.first
      end

      $device = @device
      puts "Picked #{@device.name.to_s.green}" unless @device.nil?
    end

    def android_sdk_root_is_defined
      @sdk = if !Gem.win_platform?
               `echo $ANDROID_SDK_ROOT`.delete('\n')
             else
               `echo %ANDROID_SDK_ROOT%`.delete('\n')
             end
      !@sdk.empty?
    end

    def wipe_temporary_folder
      tmpdir = Dir.tmpdir + '/dryrun/'
      puts 'Wiping ' + tmpdir.red
      FileUtils.rm_rf tmpdir
      puts 'Folder totally removed!'.green
      exit 1
    end

    def call
      unless android_sdk_root_is_defined
        puts "\nWARNING: your #{'$ANDROID_SDK_ROOT'.yellow} is not defined\n"
        puts "\nhint: in your #{'~/.bashrc'.yellow} or #{'~/.bash_profile'.yellow}  add:\n  #{"export ANDROID_SDK_ROOT='/Users/cesarferreira/Library/Android/sdk/'".yellow}"
        puts "\nNow type #{'source ~/.bashrc'.yellow}\n\n"
        exit 1
      end

      if @url.nil?
        puts 'You need to insert a valid GIT URL/folder'
        exit 1
      end

      pick_device

      if DryrunUtils::is_folder? (@url)
        repository_path = File.expand_path @url
      else

        @url = @url.split('?').first
        @url.chop! if @url.end_with? '/'

        github = Github.new(@url)

        unless github.valid?
          puts "#{@url.red} is not a valid git @url"
          exit 1
        end

        # clone the repository
        repository_path = github.clone(@branch, @tag, @cleanup)

      end

      android_project = AndroidProject.new(repository_path, @app_path, @custom_module, @flavour, @device)

      # is a valid android project?
      unless android_project.valid?
        puts "#{@url.red} is not a valid android project"
        exit 1
      end

      puts "Using custom app folder: #{@app_path.green}" if @app_path
      puts "Using custom module: #{@custom_module.green}" if @custom_module

      # clean and install the apk
      android_project.execute_command(@command)

      puts "\n> If you want to remove the app you just installed, execute:\n#{android_project.uninstall_command.yellow}\n\n"
    end
  end
end
