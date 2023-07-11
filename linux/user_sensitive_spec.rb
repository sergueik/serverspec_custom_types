require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# https://www.ruby-forum.com/t/get-current-user-logged-in-to-local-computer/136885/2

context 'user sensitive' do
  root_home = '/root'
  # condition at the 'describe' level
  context 'home directory' do
    describe command('echo $HOME'), :if => ENV.fetch('USER').eql?('root') do
      its(:stdout) { should match Regexp.new(root_home) }
    end
    describe command('echo $HOME'), :unless => ENV.fetch('USER').eql?('root') do
      its(:stdout) { should_not match Regexp.new(root_home) }
    end
  end
  # condition at the 'context' level
  context 'home directory', :if => ENV.fetch('USER').eql?('root') do
    describe command('echo $HOME') do
      its(:stdout) { should match Regexp.new(root_home) }
    end
  end
  context 'home directory', :unless => ENV.fetch('USER').eql?('root') do
    describe command('echo $HOME') do
      its(:stdout) { should_not match Regexp.new(root_home) }
    end
  end
  # include branch condition in the 'title' property
  context "home directory of #{ENV.fetch('USER')}" do
    describe command('echo $HOME') do
      its(:stdout) { should_not be_empty }
    end
  end
end	
