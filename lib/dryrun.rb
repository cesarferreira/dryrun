require 'optparse'
require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'open-uri'
require 'dryrun/github'
require 'dryrun/version'
require 'dryrun/android_project'
require 'highline/import'
require 'openssl'
require 'uri'
require 'open3'
require_relative 'dryrun/device'

module Dryrun
  class MainApp
    def initialize(arguments)

      outdated_verification

      @url = %w(-h --help -v --version -w --wipe).include?(arguments.first) ? nil : arguments.shift

      # defaults
      @app_path = nil
      @custom_module = nil
      @flavour = ''
      @build_type = ''
      @keystore_path = nil
      @tag = nil
      @branch = 'master'
      @devices = Array.new
      @cleanup = false

      # Parse Options
      # arguments.push "-h" unless @url
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

        opts.on('--build_type BUILD_TYPE', 'Custom buildType (e.g. srv1, srv2)') do |build_type|
          @build_type = build_type.capitalize
        end

        opts.on('-k', '--keystore KEYSTORE', 'Custom keystore path') do |keystore|
          @keystore_path = keystore
        end

        opts.on('-p PATH', '--path PATH', 'Custom path to android project') do |app_path|
          @app_path = app_path
        end

        opts.on('-t TAG', '--tag TAG', 'Checkout tag/commit hash to clone (e.g. "v0.4.5", "6f7dd4b")') do |tag|
          @tag = tag
        end

        opts.on('-c', '--cleanup', 'Clean the temporary folder before cloning the project') do |cleanup|
          @cleanup = true
        end

        opts.on('-w', '--wipe', 'Wipe the temporary dryrun folder') do |irrelevant|
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
      end until %w(y n s).include?(input.downcase)

      if input.downcase.eql? 'y'
        DryrunUtils.execute('gem update dryrun')

      end

    end

    def pick_device
      @@device = nil

      if !Gem.win_platform?
        @@sdk = `echo $ANDROID_HOME`.gsub("\n", '')
        @@sdk = @@sdk + '/platform-tools/adb'
      else
        @@sdk = `echo %ANDROID_HOME%`.gsub("\n", '')
        @@sdk = @@sdk + '/platform-tools/adb.exe'
      end

      puts 'Searching for devices...'.yellow

      @devices = DryrunUtils.run_adb('devices')

      if @devices == nil || @devices.empty?
        puts 'Killing adb, there might be an issue with it...'
        DryrunUtils.run_adb('kill-server')
        @devices = DryrunUtils.run_adb('devices')
      end

      if @devices.empty?
        puts "No devices attached, but I'll run anyway"
      end

      if @devices.size >= 2
        puts 'Pick your device (1,2,3...):'

        @devices.each_with_index.map { |key, index| puts "#{index.to_s.green} -  #{key.name} \n" }

        a = gets.chomp

        if a.match(/^\d+$/) && a.to_i <= (@devices.length - 1) && a.to_i >= 0
          @@device = @devices[(a.to_i)]
        else
          @@device = @devices.first
        end
      else
        @@device = @devices.first
      end

      puts "Picked #{@@device.name.to_s.green}" if @@device != nil
    end

    def self.getSDK # :yields: stdout
      @@sdk
    end

    def self.getDevice # :yields: stdout
      @@device
    end

    def android_home_is_defined
      if !Gem.win_platform?
        sdk = `echo $ANDROID_HOME`.gsub("\n", '')
      else
        sdk = `echo %ANDROID_HOME%`.gsub("\n", '')
      end
      !sdk.empty?
    end

    def check_keystore_path(repository_path)
      # Clone the debug.keystore file
      scan_result = @keystore_path.scan(URI.regexp).to_a
      load_debug_keystore(scan_result, repository_path)
    end

    def load_debug_keystore(scan_result, repository_path)
      if !scan_result.empty?
        load_keystore_from_url(repository_path)
      else
        copy_to_app_folder(repository_path)
      end
    end

    def load_keystore_from_url(repository_path)
      begin
        open(@keystore_path, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}) do |f|
          debug_keystore = f.read
          File.open(repository_path + '/app/debug.keystore', 'wb') do |new_file|
            new_file.write(debug_keystore)
          end
        end
      rescue Exception => network_error
        puts "Error occurred while loading keystore from url: #{@keystore_path} => #{network_error}"
        exit 1
      end
    end

    def copy_to_app_folder(repository_path)
      begin
        FileUtils.cp(@keystore_path, repository_path + '/app/')
      rescue Exception => file_error
        puts "Error occurred while loading keystore from local path: #{@keystore_path} => #{file_error}"
        exit 1
      end
    end


    def wipe_temporary_folder
      tmpdir = Dir.tmpdir + '/dryrun/'
      puts 'Wiping ' + tmpdir.red
      FileUtils.rm_rf tmpdir
      puts 'Folder totally removed!'.green
      exit 1
    end

    def call
      unless android_home_is_defined
        puts "\nWARNING: your #{'$ANDROID_HOME'.yellow} is not defined\n"
        puts "\nhint: in your #{'~/.bashrc'.yellow} or #{'~/.bash_profile'.yellow}  add:\n  #{"export ANDROID_HOME=\"/Users/cesarferreira/Library/Android/sdk/\"".yellow}"
        puts "\nNow type #{'source ~/.bashrc'.yellow}\n\n"
        exit 1
      end

      if @url.nil?
        puts 'You need to insert a valid GIT URL'
        exit 1
      end

      @url = @url.split("?").first
      @url.chop! if @url.end_with? '/'


      pick_device

      github = Github.new(@url)

      unless github.is_valid
        puts "#{@url.red} is not a valid git @url"
        exit 1
      end

      # clone the repository
      repository_path = github.clone(@branch, @tag, @cleanup)

      if @keystore_path
        check_keystore_path(repository_path)
      end

      android_project = AndroidProject.new(repository_path, @app_path, @custom_module, @flavour, @build_type, @device)

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
