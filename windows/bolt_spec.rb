require_relative '../windows_spec_helper'

context 'Bolt' do

# A 32-bit windows msi installer is not easily available for
# Puppet 6's Bolt
# https://puppet.com/docs/bolt/latest/bolt_installing.html
# and Puppet Agent 1.10 's embedded Ruby needs an gem upgrade
# However it appears easy to installl Bold as gem 
# inside the uru Ruby 2.3.x environment:
# The only drawback it will bring together its 55 dependencies 
# https://www.google.com/search?q=puppet%20bold%20powwershell%20task%20example

$user = ENV.fetch('USERNAME', 'vagrant')
# on a standalone Windows machine, userdomain will be same as hostname 
$hostname = ENV.fetch('USERDOMAIN', nil) 
# $env:PASSWORD='Your AD password'
$password = ENV.fetch('PASSWORD', 'vagrant')
[
  'localhost',
  $hostname
].each do |hostname|
    $stderr.puts "ruby c:/uru/ruby/lib/ruby/gems/2.3.0/gems/bolt-1.21.0/exe/bolt command run 'Get-Process' --nodes winrm://#{hostname} --no-ssl --user '#{$user}' --password '#{$password}'"
    describe command(<<-EOF
      ruby ./gems/2.3.0/gems/bolt-1.21.0/exe/bolt command run 'Get-Process' --nodes winrm://#{hostname} --no-ssl --user '#{$user}' --password '#{$password}'
     EOF
    ) do
     [ 
      "Started on #{hostname}...",
      "Finished on #{hostname}:",
     ].each do |line|
        its(:stdout) { should contain line }
      end
      its(:stderr) { should be_empty }
    end 
  end
end