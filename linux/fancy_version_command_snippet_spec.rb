# -*- mode: ruby -*-
# vi: set ft=ruby :
# origin: https://github.com/iBossOrg/docker-dockerspec/blob/master/spec/docker/10_docker_image_spec.rb
# composes expectations in the Rails DSL (?) - style

require 'spec_helper'

describe 'Command as subject' do
  # supported
  # [binary, version, args]
  # acceptable simply :binary
  [
    ['/bin/java','1.8.0_212','-version'],
      # javac does not support the -- argument style
      # override the version arg
    '/bin/javac',

  ].each do |binary_path, version, args|
    describe "Command \"#{binary_path}\"" do
      subject { file(binary_path) }
      let(:version_regex) { /\W#{version}\W/ }
      let(:version_command) { "#{binary_path} #{args.nil? ? '--version' : args}" }
      it "should be installed #{version.nil? ? nil : " with version \"#{version}\""}" do
        expect(subject).to exist
        expect(file(binary_path)).to be_executable
        expect(command(version_command).stderr).to match(version_regex) unless version.nil?
      end
    end
  end
end


