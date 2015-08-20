require 'tmpdir'
require 'fileutils'
require 'uri'
require 'colorize'

module DryRun

  class Github
    def initialize(url)
      @base_url = url

      begin
        @resource = URI.parse(url)
      rescue Exception => e
        puts "Invalid github url".red
        puts "Valid example: #{'https://github.com/cesarferreira/colorize'.green}"
        exit 1
      end
    end

    def path
      @resource.path
    end

    def is_valid
      return true
    end

    def clonable_url
      # if @base_url.split(//).last(4).join.eql? ".git" or @base_url.split(//).first(4).join.eql? "git@"
      #   @base_url
      # else
      "#{@base_url}.git"
      # end
    end

    ##
    ## CLONE THE REPOSITORY
    ##
    def clone
      clonable = self.clonable_url

      tmpdir = Dir.tmpdir+"#{path}"
      FileUtils.rm_rf(tmpdir)

      system("git clone #{clonable} #{tmpdir}")

      tmpdir
    end

  end

end
