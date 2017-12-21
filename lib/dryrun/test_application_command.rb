require_relative 'dryrun_utils'
require_relative 'android_utils'

module Dryrun
  class TestApplicationCommand

    def run(builder, package, launcher_activity, custom_module, flavour, device)
      execute_line = get_execution_command_line(package)
      builder.clean

      if device.nil?
        puts 'No devices picked/available, proceeding with unit tests instead'.green
        builder.run_unit_tests(custom_module, flavour)
      else
        builder.run_android_tests(custom_module, flavour)
      end

      unless device.nil?
        AndroidUtils.clear_app_data(package)
        AndroidUtils.pretty_run(execute_line, package)
      end
    end

    def get_execution_command_line(package)
      "adb shell am instrument -w #{package}"
    end
  end
end
