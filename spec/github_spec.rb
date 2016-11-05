require 'spec_helper'
require 'dryrun/github'
describe '#github' do
  context 'when given github url\'s' do
    it 'is a regular url' do
      url = 'https://github.com/cesarferreira/android-helloworld'
      github = Dryrun::Github.new(url)
      expected = 'https://github.com/cesarferreira/android-helloworld.git'
      expect(github.clonable_url == expected).to be true
    end

    it 'ends in .git' do
      url = 'https://github.com/googlesamples/google-services.git'
      github = Dryrun::Github.new(url)
      expected = 'https://github.com/googlesamples/google-services.git'
      expect(github.clonable_url == expected).to be true
    end

    it 'is from ssh' do
      url = 'git@github.com:cesarferreira/android-helloworld.git'
      github = Dryrun::Github.new(url)
      expected = 'git@github.com:cesarferreira/android-helloworld.git'
      expect(github.clonable_url == expected).to be true
    end

    it 'is not an url' do
      url = 'asdasdas'
      github = Dryrun::Github.new(url)
      expect(github.valid?).to be false
    end
  end
end
