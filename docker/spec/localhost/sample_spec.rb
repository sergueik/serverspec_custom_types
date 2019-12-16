require "docker_helper"
require 'spec_helper'


# just verifies the Dockerfile DSL
describe "Dockerfile" do
  describe docker_image('serverspec-example') do
    # Execute Serverspec commands locally
    before(:each) { set :backend, :exec }
    it { should exist }
  end
  before(:all) do
    @image = Docker::Image.build_from_dir('.')
    # not ready for tagging
    # @image.tag(repo: 'ignore', tag: 'latest')

    set :os, family: :alpine
    set :backend, :docker
    set :docker_image, @image.id
    set :docker_container_create_options, { 'Entrypoint' => ['ash'] }
  end
  it "should have the maintainer label" do
    expect(@image.json["Config"]["Labels"].has_key?("maintainer"))
  end
  xit "should execute rspec" do
    expect(@image.json["Config"]["Entrypoint"][0]).to eq("rake")
  end

  it "should run rspec via rake by default" do
    expect(@image.json["Config"]["Cmd"][0]).to eq("rake")
    expect(@image.json["Config"]["Cmd"][1]).to eq("spec")
  end
context 'Instance scope' do
  before(:each) do
    # NOTE: the instance scope tests still need to run through docker backend
    #
    # set :backend, :exec
    set :backend, :docker
  end
  describe "Operating system" do
    context "family" do
      subject { os[:family] }
      xit { is_expected.to eq("alpine") }
      # NOTE: not string, need a symbol
      it { is_expected.to eq :alpine  }
    end
  end
  %w|
    build-base
    libcurl
    libxml2-dev
    libxslt-dev
    libffi-dev
    libmcrypt-dev
    openssl
  |.each do |package_name|
    describe package package_name do
      it { should be_installed }
    end
  end

  [
    'Gemfile',
    'Gemfile.lock',
  ].each do | file |
    describe file("/#{ file }") do
      it { should_not exist }
    end
  end

  [
    'Rakefile',
    'spec/spec_helper.rb',
    'spec/docker_helper.rb',
  ].each do | file |
    describe file("/serverspec/#{file}") do
      it { should exist }
    end
  end
  [
    'docker-api',
    'rspec',
    'rspec_junit_formatter',
    'serverspec',
  ].each do | gem |
    describe package(gem) do
      it { should be_installed.by('gem') }
    end
  end

end
end
