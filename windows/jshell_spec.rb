if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end
require 'spec_helper'

# https://javatutorial.net/java-9-jshell-example
context 'Jshell' do

  context 'Basic' do
    # Tested with https://www.azul.com/downloads/zulu-community/
    java_basedir = 'c:/java'
    {
      'zulu9.0.7.1-jdk9.0.7-win_i686' => '9.0.7.1',
      'zulu10.3+5-jdk10.0.2-win_i686' => '10.0.2',
     }.each do |distr,version|
       java_release =  "#{java_basedir}/#{distr}"
       describe command( <<-EOF
        where.exe jshell.*
      EOF
      ) do
        let(:path) { "#{java_release}/bin" }
        its(:exit_status) { should eq 0 }
        # need to escape '+' as well as '\'
        # its (:stdout) { should match Regexp.new("#{java_release}/bin/jshell.exe".gsub(/\//, '\\\\\\\\')) }
        its (:stdout) { should match Regexp.new(Regexp.escape("#{java_release}/bin/jshell.exe".gsub(/\//, '\\\\'))) }
      end
      describe command( <<-EOF
        jshell -version
      EOF
      ) do
        let(:path) { "#{java_release}/bin" }
        its(:exit_status) { should eq 0 }
        its(:stdout) { should contain "jshell #{version}" }
      end
    end
  end
end
