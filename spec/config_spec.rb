require 'spec_helper'
require 'dryrun/config'

describe '#config' do
  context 'when load' do
    it 'from a nonexistent file' do
      allow(File).to receive(:exist?).with('config').and_return(false)
      expect{ DryRun::Config.load() }.to raise_error(RuntimeError, 'No config file is detected, please save it first.')
    end

    it 'from an existing file but with invalid ANDROID_HOME' do
      invalid_path = '/Users/abc/opt/android-sdk-macosx'
      allow(File).to receive(:exist?).with('config').and_return(true)
      allow(File).to receive(:exist?).with(invalid_path).and_return(false)
      file = instance_double('File')
      allow(File).to receive(:open).and_yield(file)
      allow(file).to receive(:gets).and_return(invalid_path)

      path = DryRun::Config.load()
      expect(path).to be_nil
    end

    it 'from an existing file with valid ANDROID_HOME' do
      expected = '/Users/abc/opt/android-sdk-macosx'
      allow(File).to receive(:exist?).with('config').and_return(true)
      allow(File).to receive(:exist?).with(expected).and_return(true)
      file = instance_double('File')
      allow(File).to receive(:open).and_yield(file)
      allow(file).to receive(:gets).and_return(expected)

      path = DryRun::Config.load()
      expect(path).to eq(expected)
    end
  end

  context 'when save' do
    it 'a valid ANDROID_HOME' do
      path = '/Users/abc/opt/android-sdk-macosx'
      allow(File).to receive(:exist?).with(path).and_return(true)
      file = instance_double('File')
      allow(File).to receive(:open).and_yield(file)
      expect(file).to receive(:puts).with(path)

      DryRun::Config.save(path)
    end

    it 'an invalid ANDROID_HOME' do
      path = '/Users/abc/opt/android-sdk-macosx'
      allow(File).to receive(:exist?).with(path).and_return(false)

      expect{ DryRun::Config.save(path) }.to raise_error(SystemExit)
    end
  end
end
