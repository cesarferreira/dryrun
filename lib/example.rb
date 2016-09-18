require 'adb-sdklib'
require 'optparse'
require 'colorize'
require 'tmpdir'
require 'fileutils'
require 'dryrun/github'
require 'dryrun/version'
require 'dryrun/android_project'
require "highline/import"
require 'openssl'
require 'open3'
require_relative 'dryrun/device'


def run_adb(args, adb_opts = {}, &block) # :yields: stdout
  adb_arg = ""
  path = "#{@sdk} #{adb_arg} #{args} "
  last_command = path
  run(path, &block)
end

def run(path, &block)
  @last_command = path
  Open3.popen3(path) do |stdin, stdout, stderr, wait_thr|
   stdout.each do |line|
    line = line.strip
    if (!line.empty? && line !~ /^List of devices/)
      parts = line.split
      device = AdbDevice::Device.new(parts[0], parts[1])
      @devices << device
    end
  end
end
end

@devices = Array.new

if !Gem.win_platform?
  @sdk = `echo $ANDROID_HOME`.gsub("\n",'')
  @sdk = @sdk + "/platform-tools/adb";
else
  @sdk = `echo %ANDROID_HOME%`.gsub("\n",'')
  @sdk = @sdk + "/platform-tools/adb.exe"
end

run_adb("devices")

if(@devices == nil || @devices.length == 0)
  puts "No Device Found!"
else if(@devices.length == 1)
  puts "Device is already one processing..."
#TODO device is only one continue here the processing
else
  @devices.each_with_index do |item, i|
    puts "Choose a device"
    puts "(#{i}+1) - #{item.name}"
  end
end
end
