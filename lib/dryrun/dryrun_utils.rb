require 'open-uri'
require 'dryrun/version'
require 'open3'

module Dryrun
	class DryrunUtils

		def self.execute(command)
			is_success = system command
			unless is_success
				puts "\n\n======================================================\n\n"
				puts " Something went wrong while executing this:".red
				puts "  $ #{command}\n".yellow
				puts "======================================================\n\n"
				exit 1
			end
		end

		def self.get_latest_version
			url = 'https://raw.githubusercontent.com/cesarferreira/dryrun/master/lib/dryrun/version.rb'
			page_string = nil

			if Gem.win_platform?
				open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}) do |f|
					page_string = f.read
				end
			else
				open(url) do |f|
					page_string = f.read
				end
			end

			page_string[/#{Regexp.escape('\'')}(.*?)#{Regexp.escape('\'')}/m, 1]
		end

		def self.is_up_to_date
			latest = get_latest_version
			latest.to_s <= Dryrun::VERSION.to_s
		end

		def self.run_adb(args, adb_opts = {}, &block) # :yields: stdout
			adb_arg = ""
			adb_arg += " -s #{Dryrun::MainApp.getDevice}"
			path = "#{Dryrun::MainApp.getSDK} #{adb_arg} #{args} "
			run(path, &block)
		end

		def self.run(path, &block)
			Open3.popen3(path) do |stdin, stdout, stderr, wait_thr|
				devices = Array.new()
				stdout.each do |line|
					line = line.strip
					if (!line.empty? && line !~ /^List of devices/)
						parts = line.split
						devices << AdbDevice::Device.new(parts[0], parts[1])
					end
				end
				return devices
			end
		end
	end
end
