require 'open-uri'
require_relative 'lib/dryrun/version'

def get_latest_version
  url = 'https://raw.githubusercontent.com/cesarferreira/dryrun/master/lib/dryrun/version.rb'
  page_string = nil

  open(url) do |f|
    page_string = f.read
  end

  page_string[/#{Regexp.escape('\'')}(.*?)#{Regexp.escape('\'')}/m, 1]
end

def am_I_updated
  latest = get_latest_version
  latest.eql? DryRun::VERSION
end

# puts am_I_updated
