require 'tmpdir'
require 'fileutils'
require 'uri'

module DryRun

  class Github
    def initialize(url)
      @base_url = url
      @destination = get_destination
    end

    def get_destination
      destiny = @base_url.gsub('.git','')
      destiny = destiny.split('/')
      destiny = destiny.last(2).join('/')
      destiny = destiny.gsub('git@github.com:','')
      destiny
    end

    def is_valid
      return true
    end

    def clonable_url
      starts_with_git = @base_url.split(//).first(4).join.eql? "git@"
      ends_with_git = @base_url.split(//).last(4).join.eql? ".git"

      # ends with git but doesnt start with git
      if ends_with_git and !starts_with_git
        return @base_url
      end

      # ends with git but doesnt start with git
      if !ends_with_git and !starts_with_git
        return "#{@base_url}.git"
      end

      @base_url

      # end
    end

    ##
    ## CLONE THE REPOSITORY
    ##
    def clone
      clonable = self.clonable_url

      tmpdir = Dir.tmpdir+"/dryrun/#{@destination}"
      FileUtils.rm_rf(tmpdir)

      system("git clone #{clonable} #{tmpdir}")

      tmpdir
    end

  end

end
