module DryRun
  class Config
    @@file = File.expand_path('../../', File.dirname(__FILE__)) + '/config'

    class << self
      def load
        if File.exist?(@@file)
          path = nil
          File.open(@@file, 'r') do |f|
            path = f.gets.chomp
          end
          return (File.exist?(path) ? path : nil)
        else
          fail('No config file is detected, please save it first.')
        end
      end

      def save(path)
        if File.exist?(path)
          File.open(@@file, 'w') do |f|
            f.puts path
          end
          puts 'Config file is saved.'
        else
          puts 'Invalid path, config is not saved.'
          exit 1
        end
      end
    end
  end
end