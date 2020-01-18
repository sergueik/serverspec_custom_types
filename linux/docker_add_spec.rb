# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'docker_helper'
require 'spec_helper'

# origin: https://github.com/mtromp/tdd-jenkins-docker/blob/master/spec/Dockerfile_spec.rb

# expect every file in source directory to be copied into Docker image
context 'Added files present' do
  srcdir = 'spec'	
  basedir = '/serverspec'
  destdir = "{basedir}/spec"
  Dir["#{srcdir}/*"].each do |filename|
    add_file = "#{destdir}/#{filename}"
    it "Verify file exists: #{add_file}" do
      expect(file(add_file)).to exist
    end
  end
end
