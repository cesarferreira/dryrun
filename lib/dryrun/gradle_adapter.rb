require_relative 'dryrun_utils'

module Dryrun
  class GradleAdapter

    def initialize(builder)
      @builder = builder
    end

    def clean
      DryrunUtils.execute("#{@builder} clean")
    end

    def run_android_tests(custom_module, flavour)
      if custom_module
        puts "#{@builder} :#{custom_module}:connected#{flavour}DebugAndroidTest"
        DryrunUtils.execute("#{@builder} :#{custom_module}:connected#{flavour}DebugAndroidTest")
      else
        puts "#{@builder} connected#{flavour}DebugAndroidTest"
        DryrunUtils.execute("#{@builder} connected#{flavour}DebugAndroidTest")
      end
    end

    def run_unit_tests(custom_module, flavour)
      if custom_module
        puts "#{@builder} :#{custom_module}:test#{flavour}DebugUnitTest"
        DryrunUtils.execute("#{@builder} :#{custom_module}:test#{flavour}DebugUnitTest")
      else
        puts "#{@builder} test#{flavour}DebugUnitTest"
        DryrunUtils.execute("#{@builder} test#{flavour}DebugUnitTest")
      end
    end

    def install(custom_module, flavour)
      if custom_module
        puts "#{@builder} :#{custom_module}:install#{flavour}Debug"
        DryrunUtils.execute("#{@builder} :#{custom_module}:install#{flavour}Debug")
      else
        puts "#{@builder} install#{flavour}Debug"
        DryrunUtils.execute("#{@builder} install#{flavour}Debug")
      end
    end


    def assemble(custom_module, flavour)
      if custom_module
        puts "#{@builder} :#{custom_module}:assemble#{flavour}Debug"
        DryrunUtils.execute("#{@builder} :#{custom_module}:assemble#{flavour}Debug")
      else
        puts "#{@builder} assemble#{flavour}Debug"
        DryrunUtils.execute("#{@builder} assemble#{flavour}Debug")
      end
    end
  end
end
