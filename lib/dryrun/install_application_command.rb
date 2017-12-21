require_relative 'dryrun_utils'
require_relative 'android_utils'

module Dryrun
  class InstallApplicationCommand

    def run(builder, package, launcher_activity, custom_module, flavour, device)
      execute_line = get_execution_command_line(package, launcher_activity)
      if custom_module
        DryrunUtils.execute("#{builder} clean")
        DryrunUtils.execute("#{builder} :#{custom_module}:install#{flavour}Debug")
      else
        DryrunUtils.execute("#{builder} clean")

        if device.nil?
          puts 'No devices picked/available, proceeding with assemble instead'.green
          puts "#{builder} assemble#{flavour}Debug"
          DryrunUtils.execute("#{builder} assemble#{flavour}Debug")
        else
          puts "#{builder} install#{flavour}Debug"
          DryrunUtils.execute("#{builder} install#{flavour}Debug")
        end
      end

      unless device.nil?
        AndroidUtils.clear_app_data(package)
        AndroidUtils.pretty_run(execute_line, package)
      end
    end

    def get_execution_command_line(package, launcher_activity)
      "am start -n \"#{launcheable_activity(package, launcher_activity)}\" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
    end

    def launcheable_activity(package, launcher_activity)
      full_path_to_launcher = "#{package}#{launcher_activity.gsub(package, '')}"
      "#{package}/#{full_path_to_launcher}"
    end
  end
end
