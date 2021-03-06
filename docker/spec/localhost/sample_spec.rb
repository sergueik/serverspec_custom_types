require 'docker_helper'
require 'spec_helper'
require 'pp'

if ENV.fetch('DEBUG', false) =~ /^(true|t|yes|y|1)$/i
  DEBUG = true
else
  DEBUG = false
end
$stderr.puts ('DEBUG=' + DEBUG.to_s )

describe 'Docker Image' do
  # based on: https://github.com/ikauzak/dockerfile_tdd
  expected_key = 'tag_test'
  before(:all) do
    @image = Docker::Image.build_from_dir('.')
    # craft few entries not originally in the image 
    @image.tag(repo: expected_key, tag: 'latest')
    set :os, family: :alpine
    set :backend, :docker
    set :docker_image, @image.id
    set :docker_container_create_options, { 'Entrypoint' => ['ash']}
  end
  it "should have the #{expected_key}" do
    if DEBUG
      PP.pp @image.json, $stderr
    end
    # expect(@image.json['Config']['Labels'].has_key?(expected_key))
    expect(@image.json['Config'].has_key?('WorkingDir'))
    expect(@image.json['Config']['WorkingDir'].eql?('/serverspec'))
    expect(@image.json['Config'].has_key?('Cmd'))
    [
      'rake',
      'spec'
    ].each do |command|
      expect(@image.json['Config']['Cmd'].include?(command))
    end
  end
end


# the following largely just verifies Dockerfile DSL
describe 'Dockerfile' do
  before(:all) do
    @image = Docker::Image.build_from_dir('.')
    # not ready for tagging
    # @image.tag(repo: 'ignore', tag: 'latest')

    set :os, family: :alpine
    set :backend, :docker
    set :docker_image, @image.id
    set :docker_container_create_options, { 'Entrypoint' => ['ash'] }
  end
  it 'should have the maintainer label' do
    expect(@image.json['Config']['Labels'].has_key?('maintainer'))
  end
  it 'should run rspec via rake by default' do
    expect(@image.json['Config']['Entrypoint']).to be_nil
    expect(@image.json['Config']['Cmd'][0]).to eq 'rake'
    expect(@image.json['Config']['Cmd'][1]).to eq 'spec'
  end
end

context 'Instance scope' do
  before(:each) do
    # NOTE: the following instance scope tests still need
    # to be run through docker backend
    #
    # set :backend, :exec
    set :backend, :docker
  end
  describe 'Operating system' do
    context 'family' do
      subject { os[:family] }
      # NOTE: for this expectation one needs a symbol, not a string
      it { is_expected.to eq :alpine  }
      it { is_expected.not_to eq 'alpine'  }
    end
  end
  %w|build-base libcurl libxml2-dev libxslt-dev libffi-dev libmcrypt-dev openssl|.each do |package_name|
    describe package package_name do
      it { should be_installed }
    end
  end
  %w|jq xmllint|.each do |tool|
    describe command ("which #{tool}") do
      its(:stdout) { should_not be_empty }
    end
  end
  describe command "jq '.foo' '/serverspec/tmp/data.json'" do
    its(:stdout) { should contain 'bar' }
  end
  describe command "xmllint --xpath '/Server/@port' '/serverspec/tmp/data.xml'" do
    its(:stdout) { should contain 'port="8005"' }
  end

  describe file ('/usr/local/bin/ruby') do
    it { should be_file }
    it { should be_executable }
  end
  [
    'Gemfile',
    'Gemfile.lock',
  ].each do |filename|
    describe file "/#{filename}" do
      it { should_not exist }
    end
  end

  [
    'Rakefile',
    'spec/spec_helper.rb',
    'spec/docker_helper.rb',
  ].each do |filename|
    describe file "/serverspec/#{filename}" do
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

describe 'Docker container' do
  before(:each) do
    set :backend, :docker
  end
  container_name = ENV.fetch('CONTAINER_NAME','serverspec-example')
  describe docker_container(container_name) do
    before(:each) { set :backend, :exec }
    it { is_expected.to be_running }
  end
  # based on:https://github.com/iBossOrg/docker-dockerspec/blob/master/spec/docker/20_docker_container_spec.rb
  [
    ['ash', 'root', 'root', 1 ],
    'ash'
  ].each do  |process, user, group, pid|
    context process(process) do
      it { is_expected.to be_running }
      its(:pid) { is_expected.to eq pid } unless pid.nil?
      its(:user) { is_expected.to eq user } unless user.nil?
      its(:group) { is_expected.to eq group } unless group.nil?
    end
  end	
end
