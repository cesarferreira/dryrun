require_relative 'dryrun_utils'

module Dryrun
  class AndroidUtils

    def self.pretty_run(execute_line, package)
      puts "Installing #{package.green}...\n"
      puts "executing: #{execute_line.green}\n"

      DryrunUtils.run_adb("shell #{execute_line}")
    end

    def self.clear_app_data(package)
      DryrunUtils.run_adb("shell pm clear #{package}")
    end
  end
end
