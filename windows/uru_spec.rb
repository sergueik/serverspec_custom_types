if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

require 'type/property_file'

context 'Custom Type' do
  file_path = 'C:/Users/vagrant/sample.properties'
  describe property_file(file_path) do
    it { should have_property('package.class.property', 'value' ) }
  end
end

# Example emulates an apache configuration file
# from '/etc/httpd/conf.d/'

context 'Virtual Host' do
  base_path = 'C:/Users/vagrant/sample/conf'
  file_mask = 'sample.conf'

  before(:all) do
    Specinfra::Runner::run_command( <<-EOF
      pushd $base_path

      @'
 <VirtualHost *:80>
   <Location / >
     AuthType Basic
     AuthName "account name"
     AuthPassword "password"
    </Location>
  <Directory "/var/www">
   Options Indexes FollowSymLinks MultiViews
   AllowOverride None
   Require all granted
 </Directory>
</VirtualHost>

'@ | out-file -FilePath ('{0}' -f $file_mask ) -Encoding 'ascii'
      popd
  EOF
  ) end

  Dir.glob("#{base_path}/*").each do |file_path|
    next if File.directory?(file_path)
    config_file = File.basename(file_path)
    next unless config_file =~ /#{file_mask}/
    describe property_file(file_path) do
      {
        'AuthType' => 'Basic',
        'AuthName'  => "account name",
        'AuthPassword'=> "password",
      }.each do |key, value|
        it { should have_property(key, value ) }
      end
      [
        'Options Indexes FollowSymLinks MultiViews',
        'AllowOverride None',
        'Require all granted',
      ].each do |line|
        it { should have_configuration(line ) }
      end
    end
  end
end
context 'Testing Framework' do

  uru_home = 'd:/testing_framework'
  user_home = ENV.has_key?('VAGRANT_EXECUTABLE') ? 'c:/users/vagrant' : ('c:/users/' + ENV['USER'] )
  gem_version='2.1.0'

  # This test only pass under uru runtime, and fail when run by vagrant-serverspec
  context 'URU specifics', :if => ENV.has_key?('URU_INVOKER')   do

    context 'Path' do
      describe command(<<-EOF
       pushd env:
       dir 'PATH' | format-list
       popd
        EOF
      ) do
        its(:stdout) { should match Regexp.new(
              '_U1_;' +
              uru_home.gsub('/','[/|\\\\\\\\]') +
              '\\\\ruby\\\\bin' + ';_U2_',
              Regexp::IGNORECASE
            )
        }
      end
    end

    context 'Environment variable' do
      describe command(<<-EOF
       pushd env:
       dir 'URU_INVOKER' | format-list
       popd
        EOF
      ) do
        its(:stdout) { should match /powershell|bash/i }
      end
    end
  end

  context 'Directories' do
    describe file(uru_home) do
      it { should be_directory }
    end
    describe file("#{user_home}/.uru") do
      it { should be_directory }
    end
    describe file("#{user_home}/.uru/rubies.json") do
      it { should be_file }
    end
  end

  context 'Executables' do
    [
     'uru_rt.exe',
      'runner.ps1',
      'reporter.rb'].each do |file|
      describe file("#{uru_home}/#{file}") do
        it { should be_file }
      end
    end
  end
end

