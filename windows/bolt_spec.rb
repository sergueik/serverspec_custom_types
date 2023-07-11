require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Bolt' do

  bolt_version = '1.21.0'
  ruby_version = '2.3.0'

  # A 32-bit windows msi installer is not easily available for
  # Puppet 6's Bolt url.
  # https://puppet.com/docs/bolt/latest/bolt_installing.html
  # and Puppet Agent 1.10 's embedded Ruby needs an gem upgrade
  # The solution is install Bold gem
  # inside the uru Ruby environment - require uru with Ruby 2.3.x+
  # drawback is 50+ bolt's gem dependencies, listed below
  # will be installed
  # NOTE: as announced by https://puppet.com/docs/bolt/latest/bolt_installing.html#install-bolt-as-a-gem
  # Starting with Bolt 0.20.0, gem installations no longer include core task modules.
  # they want one to use one of their Bolt installation packages instead of a gem.

  $user = ENV.fetch('USERNAME', 'vagrant')
  # on a standalone Windows machine, userdomain will be same as hostname
  $hostname = ENV.fetch('USERDOMAIN', nil)
  # NOTE: before running this example need to set $env:PASSWORD='Your AD password'
  $password = ENV.fetch('PASSWORD', 'vagrant')

  [
    'localhost',
    $hostname
  ].each do |hostname|
    $stderr.puts "ruby c:/uru/ruby/lib/ruby/gems/2.3.0/gems/bolt-1.21.0/exe/bolt command run 'Get-Process' --nodes winrm://#{hostname} --no-ssl --user '#{$user}' --password '#{$password}'"
    # https://www.google.com/search?q=puppet%20bold%20powwershell%20task%20example
    describe command(<<-EOF
      ruby ruby/lib/ruby/gems/#{ruby_version}/gems/bolt-#{bolt_version}/exe/bolt command run 'Get-Process' --nodes winrm://#{hostname} --no-ssl --user '#{$user}' --password '#{$password}'
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
  describe command(<<-EOF
$scriptContents = @'
  # origin: http://poshcode.org/5679 for additional registry hack

$schemas = @(
  'http',
  'https',
  'ftp'
)
$browsers = @{
  'FirefoxURL' = 'Firefox';
  'Opera\\.Protocol' = 'Opera';
  'ChromeHTML' = 'Chrome';
  'IE\\..*' = 'Interner Explorer';
}
pushd 'HKCU:'
cd '/Software/Microsoft/Windows/Shell/Associations/UrlAssociations'
$schemas | ForEach-Object {
  $schema = $_
  pushd $schema
  $x = Get-ItemProperty -Path 'UserChoice' -Name 'Progid'
  $handler = $x.'Progid'
  $browsers.Keys | ForEach-Object {
    if ($handler -match $_) {
      write-host ('{0} is the default for {1}' -f $browsers[$_], $schema)
    }
  }
  popd
}
popd
'@
# there should be no leading whitespace in the line above
    $scriptPath = 'c:/temp/script.ps1'
    echo $scriptContents | out-file -literalpath $scriptPath
    $bolt = 'ruby/lib/ruby/gems/#{ruby_version}/gems/bolt-#{bolt_version}/exe/bolt'
    ruby $bolt script run $scriptPath --nodes winrm://localhost --no-ssl --user '#{$user}' --password '#{$password}'
  EOF
  ) do
    [
      'Started on localhost...',
      'Finished on localhost:',
      'Chrome is the default',
    ].each do |line|
      its(:stdout) { should contain line }
    end
    its(:stderr) { should be_empty }
  end
  # https://puppet.com/blog/introducing-masterless-puppet-bolt

  $uru_home = ENV.fetch('URU_HOME', 'c:\uru')
  describe command(<<-EOF
$plan_contents = @'
plan profiles::nginx_install(
  TargetSpec $nodes,
  String $site_content = 'hello!',
) {
  # Install puppet on the target and gather facts
  # NOTE: in standalone environment would fail with
  # puppet_agent::version could not be found
  $nodes.apply_prep

  # Compile the manifest block into a catalog
  apply($nodes) {
    file { '/Windows/Temp/index.html':
      content => $site_content,
      ensure  => file,
    }
  }
}
'@
# there should be no leading whitespace in the line above

    cd $env:USERPROFILE | out-null
    if ($env:URU_HOME -eq $null -or $env:URU_HOME -eq '') {
      $env:URU_HOME = '#{$uru_home}'
    }
    if ($env:URU_HOME -eq $null -or $env:URU_HOME -eq '') {
      $env:URU_HOME = 'c:\\uru'
    }
    write-debug ("`$env:URU_HOME = {0}" -f $env:URU_HOME)

    new-item '.puppetlabs/bolt/modules/profiles/plans' -force -itemtype directory
    $plan_path = '.puppetlabs/bolt/modules/profiles/plans/nginx_install.pp'
    $plan_name = $plan_path -replace '^.*/modules/(.+)/plans/(.+).pp$', '$1::$2'
    write-debug ('plan name: {0}' -f $plan_name)

    # NOTE: lack of -encoding option leads to error
    # illegal UTF-16 Byte Order mark at beginning of input: [FF FE] - remove these from the puppet source
    # NOTE: specifying utf8 encoding leads to error
    # illegal UTF-8 Byte Order mark at beginning of input: [EF BB BF] - remove these from the puppet source
    out-file -literalpath $plan_path -inputobject $plan_contents -encoding 'ascii'

    # NOTE: not escaping the backslash leads to error
    # the regular expression pattern \ is not valid.
    $bolt = "${env:URU_HOME}/ruby/lib/ruby/gems/#{ruby_version}/gems/bolt-#{bolt_version}/exe/bolt" -replace '\\\\', '/'
    write-output "ruby $bolt plan run $plan_name --nodes winrm://localhost --no-ssl --user '#{$user}' --password '#{$password}'"
    $env:PATH="${env:PATH};${env:URU_HOME}\\ruby\\bin"
    ruby $bolt plan run $plan_name --nodes winrm://localhost --no-ssl --user '#{$user}' --password '#{$password}'
  EOF
  ) do
    [
      'Starting: plan profiles::nginx_install',
      'Starting: install puppet and gather facts on winrm://localhost',
      'Finished: plan profiles::nginx_install',
    ].each do |line|
      its(:stdout) { should contain line }
    end
    # add a guaranteed to fail to actually see the output
    its(:stdout) { should_not contain 'plan' }
    its(:stderr) { should be_empty }
  end
end

# https://devhints.io/bolt


# .\uru_rt.exe gem install --no-rdoc --no-ri bolt
#
# ruby 2.3.3p222 (2016-11-21 revision 56859) [i386-mingw32]
#
# public_suffix-3.1.0
# addressable-2.6.0
# CFPropertyList-2.3.6
# concurrent-ruby-1.1.5
# excon-0.64.0
# docker-api-1.34.2
# optimist-3.0.0
# highline-1.6.21
# hiera-eyaml-3.0.0
# little-plugger-1.1.4
# logging-2.2.2
# minitar-0.6.1
# net-ssh-5.2.0
# multipart-post-2.1.1
# faraday-0.13.1
# connection_pool-2.2.2
# net-http-persistent-3.0.1
# orchestrator_client-0.4.2
# ffi-1.9.25-x86-mingw32
# facter-2.5.1-x86-mingw32
# hiera-3.5.0
# semantic_puppet-1.0.2
# fast_gettext-1.1.2
# locale-2.1.2
# httpclient-2.8.3
# hocon-1.2.5
# puppet-resource_api-1.8.1
# win32-dir-0.4.9
# win32-process-0.7.5
# win32-security-0.2.5
# win32-service-0.8.8
# puppet-6.4.2-x86-mingw32
# colored-1.2
# cri-2.15.6
# log4r-1.1.10
# faraday_middleware-0.12.2
# text-1.3.1
# gettext-3.2.9
# gettext-setup-0.30
# puppet_forge-2.2.9
# r10k-3.3.0
# rubyntlm-0.6.2
# windows_error-0.1.2
# bindata-2.4.4
# ruby_smb-1.0.5
# unicode-display_width-1.6.0
# terminal-table-1.8.0
# builder-3.2.3
# erubis-2.7.0
# gssapi-1.3.0
# gyoku-1.3.1
# nori-2.6.0
# winrm-2.3.2
# rubyzip-1.2.3
# winrm-fs-1.3.2
# bolt-1.21.0
#
# 56 gems installed
#
