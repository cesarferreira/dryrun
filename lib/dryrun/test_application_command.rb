require_relative 'dryrun_utils'

module Dryrun
  class TestApplicationCommand

    def run(builder, package, launcher_activity, custom_module, flavour, device)
      execute_line = get_execution_command_line(package)
      if custom_module
        DryrunUtils.execute("#{builder} clean")
        DryrunUtils.execute("#{builder} :#{custom_module}:connected#{flavour}DebugAndroidTest")
      else
        DryrunUtils.execute("#{builder} clean")

        if device.nil?
          puts 'No devices picked/available, proceeding with unit tests instead'.green
          puts "#{builder} test#{flavour}DebugUnitTest"
          DryrunUtils.execute("#{builder} test#{flavour}DebugUnitTest")
        else
          puts "#{builder} connected#{flavour}DebugAndroidTest"
          DryrunUtils.execute("#{builder} connected#{flavour}DebugAndroidTest")
        end
      end

      unless device.nil?
        DryrunUtils.clean_execute(execute_line, package)
      end
    end

    def get_execution_command_line(package)
      "adb shell am instrument -w #{package}"
    end
  end
end
