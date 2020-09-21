require 'open-uri'
require 'dryrun/version'
require 'open3'

module Dryrun
  class DryrunUtils
    attr_accessor :sdk
    attr_accessor :device

    def self.execute(command)
      is_success = system command
      unless is_success
        puts "\n\n======================================================\n\n"
        puts ' Something went wrong while executing this:'.red
        puts "  $ #{command}\n".yellow
        puts "======================================================\n\n"
        exit 1
      end
    end

    def self.latest_version
      url = 'https://raw.githubusercontent.com/cesarferreira/dryrun/master/lib/dryrun/version.rb'
      page_string = nil

      if Gem.win_platform?
        open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
          page_string = f.read
        end
      else
        URI.open(url) do |f|
          page_string = f.read
        end
      end

      page_string[/#{Regexp.escape('\'')}(.*?)#{Regexp.escape('\'')}/m, 1]
    end

    def self.up_to_date
      latest = latest_version
      latest.to_s <= Dryrun::VERSION.to_s
    end

    def self.run_adb(args)
      adb_arg = " -s #{$device.name} " unless $device.nil?
      path = "#{$sdk} #{adb_arg} #{args} "
      run(path)
    end

    def self.is_folder? (path)
      File.directory?(path)
    end

    def self.run(path)
      Open3.popen3(path) do |_stdin, stdout, _stderr|
        devices = []
        stdout.each do |line|
          line = line.strip
          if !line.empty? && line !~ /^List of devices/ && !line.start_with?('adb') && !line.start_with?('*')
            parts = line.split
            devices << Dryrun::Device.new(parts[0], parts[1])
          end
        end
        devices
      end
    end
  end
end
