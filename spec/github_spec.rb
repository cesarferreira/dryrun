require 'spec_helper'
require 'dryrun/github'

describe '# Github' do

  context 'URL validity' do
    it 'URL should be valid' do
      url = 'https://github.com/cesarferreira/android-helloworld'
      github = Dryrun::Github.new(url)
      expected = 'https://github.com/cesarferreira/android-helloworld.git'
      expect(github.cloneable_url).to eq(expected)
    end

    it 'URL that ends in .git should be valid' do
      url = 'https://github.com/googlesamples/google-services.git'
      github = Dryrun::Github.new(url)
      expected = 'https://github.com/googlesamples/google-services.git'
      expect(github.cloneable_url).to eq(expected)
    end

    it 'SSH URL should be valid' do
      url = 'git@github.com:cesarferreira/android-helloworld.git'
      github = Dryrun::Github.new(url)
      expected = 'git@github.com:cesarferreira/android-helloworld.git'
      expect(github.cloneable_url).to eq(expected)
    end

    it 'URL should not be valid' do
      url = 'asdasdas'
      github = Dryrun::Github.new(url)
      expect(github.valid?).to be false
    end
  end

  context 'URL destination folders' do
    it 'Given a regular url' do
      url = 'https://github.com/cesarferreira/android-helloworld'
      github = Dryrun::Github.new(url)
      expected = 'cesarferreira/android-helloworld'
      expect(github.destination).to eq(expected)
    end

    it 'Given a URL that ends in .git' do
      url = 'https://github.com/googlesamples/google-services.git'
      github = Dryrun::Github.new(url)
      expected = 'googlesamples/google-services'
      expect(github.destination).to eq(expected)
    end

    it 'Given a SSH URL' do
      url = 'git@github.com:cesarferreira/android-helloworld.git'
      github = Dryrun::Github.new(url)
      expected = 'cesarferreira/android-helloworld'
      expect(github.destination).to eq(expected)
    end

    it 'Given a non Github URL' do
      url = 'git@bitbucket.org:RyanBis/another-android-library.git'
      github = Dryrun::Github.new(url)
      expected = '2ef4153951350a0521cd8e02e4b629072dd515637610f0b48fe17a1a89a2c51a'
      expect(github.destination).to eq(expected)
    end
  end
end
