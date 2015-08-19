require 'tmpdir'
require 'fileutils'
require 'uri'

class Github
  def initialize(url)
    # URL   | https://github.com/cesarferreira/Pretender
    # HTTPS | https://github.com/cesarferreira/Pretender.git
    # GIT   | git@github.com:cesarferreira/Pretender.git

    @base_url = url
    @resource = URI.parse(url)
  end

  def path
    @resource.path
  end

  def is_a_github_url
    return true
  end

  def clonable_url
    "#{@base_url}.git"
  end

  ##
  ## CLONE THE REPOSITORY
  ##
  def clone
    clonable = self.clonable_url

    tmpdir = Dir.tmpdir+"#{path}"
    FileUtils.rm_rf(tmpdir)

    system("git clone #{clonable} #{tmpdir}")

    Dir.chdir tmpdir

    system("ls")

    tmpdir
  end

end

