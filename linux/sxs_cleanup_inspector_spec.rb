require 'spec_helper'

context 'Application with past release polluted "side by side" directories' do
  app_base = '/tmp/appname'
  # count directories named
  # '/opt/appname/#{past_release}'
  # skipping '/opt/appname/2.4-current' '/opt/appname/current' etc.
  past_releases = %w|1.2.0 1.2.1 1.2.2 1.2.3 1.2.4|
  before(:all) do
    # $stderr.puts "Past release dirs: #{past_releases}"
    Specinfra::Runner::run_command( <<-EOF
      APP_BASE='#{app_base}'
      PAST_RELEASES='#{past_releases.join(' ').to_s}'
      1>&2 echo $PAST_RELEASES
      mkdir -p $APP_BASE
      # pushd needs bash
      cd $APP_BASE
      for D in $PAST_RELEASES ; do 1>&2 echo $D; mkdir $D; done
      mkdir 'dummy'
      ln -s '#{past_releases[0]}' latest
    EOF
    )
  end
  # counting sibling application directories
  # NOTE: filtering the directories twice
  describe command(<<-EOF
    ls -dl #{app_base}/1* | grep -E '[0-9].[0-9].[0-9]+$' | wc -l
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /#{past_releases.size}\b/ }
  end
  # TODO: Ruby version
end

