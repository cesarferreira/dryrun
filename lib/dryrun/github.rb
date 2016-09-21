require_relative 'dryrun_utils'
require 'tmpdir'
require 'fileutils'
require 'uri'
require 'digest'

module Dryrun
  class Github
    def initialize(url)
      url = url.split('?').first
      url.chop! if url.end_with? '/'

      @base_url = url
      @destination = destination
    end

    def destination
      Digest::SHA256.hexdigest @base_url
    end

    def valid?
      starts_with_git = @base_url.split(//).first(4).join.eql? 'git@'
      starts_with_http = @base_url.split(//).first(7).join.eql? 'http://'
      starts_with_https = @base_url.split(//).first(8).join.eql? 'https://'

      return (starts_with_git || starts_with_https || starts_with_http)
    end

    def clonable_url
      starts_with_git = @base_url.split(//).first(4).join.eql? 'git@'
      ends_with_git = @base_url.split(//).last(4).join.eql? '.git'

      # ends with git but doesnt start with git
      if ends_with_git && !starts_with_git
        return @base_url
      end

      # ends with git but doesnt start with git
      if !ends_with_git && !starts_with_git
        return "#{@base_url}.git"
      end

      @base_url
    end

    ##
    ## CLONE THE REPOSITORY
    ##
    def clone(branch, tag)
      clonable = clonable_url

      tmpdir = Dir.tmpdir + "/dryrun/#{@destination}"
      folder_exists = File.directory?(tmpdir)

      if folder_exists
        Dir.chdir tmpdir
        is_git_repo = system('git rev-parse')

        if !is_git_repo
          FileUtils.rm_rf(tmpdir)
          DryrunUtils.execute("git clone --depth 1 #{clonable} #{tmpdir}")
          DryrunUtils.execute("git checkout #{branch}")
        else
          puts "Found project in #{tmpdir.green}..."
          DryrunUtils.execute('git reset --hard HEAD')
          DryrunUtils.execute('git fetch --all')
          DryrunUtils.execute("git checkout #{branch}")
          DryrunUtils.execute("git pull origin #{branch}")
        end

      else
        DryrunUtils.execute("git clone --depth 1 #{clonable} #{tmpdir}")
      end

      if tag
        Dir.chdir tmpdir
        DryrunUtils.execute('git fetch --depth=10000')
        DryrunUtils.execute("git checkout #{tag}")
      end

      tmpdir
    end
  end
end
