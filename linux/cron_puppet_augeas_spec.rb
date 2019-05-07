require 'spec_helper'


context 'Using Puppet and Augtool to examine and modify Cron jobs' do
  job_name = 'unwanted-cron-job'
  # using puppet cron resource to create the crontab job
  # Will create user-specific cron:
  # '/var/spool/cron/root'
  #  # Puppet Name: TEST
  # 0,5,10,15,20,25,30,35,40,45,50,55 * * * * cmd

  before(:each) do
    Specinfra::Runner::run_command( <<-EOF
      puppet apply -e 'cron { "TEST": minute => [0,5,10,15,20,25,30,35,40,45,50,55], user => "root", command => "cmd" }
    EOF
    )
  end
  # using puppet augeas resource to remove the crontab job
  # https://github.com/cegeka/puppet-limits/blob/master/manifests/conf.pp
  # using puppet cron resource to remove the crontab job
  puppet apply -e 'augeas { "example": context => "/files/etc/crontab", onlyif  => "match entry[. = \"find\"] size > 0", changes => "rm entry[. = \"find\"]", }'
  set /augeas/load/cron/incl '/etc/crontab'
 # /opt/puppetlabs/puppet/share/augeas/lenses/dist/cron.aug
 set /augeas/load/cron/lens 'Cron.lns'
 # NOTE: Module Cron applies  to /etc/cron.d/* and /etc/crontab. but not to user cron spool files
 set /augeas/load/cron/incl '/files/var/spool/cron/root'
 load
 ls '/files/etc/crontab/entry[.="/tmp/backup.sh"]/*'
minute = 0
hour = 2
dayofmonth = *
month = *
dayofweek = *


load
ls '/files/var/spool/cron/root'
  #
  after(:each) do
    Specinfra::Runner::run_command( <<-EOF
      puppet apply -e 'cron {"#{job_name}": ensure => absent, hour => absent, minute => absent , month => ansent, monthday => absent, dayofweek => absent }'
    EOF
    )
  end
  
  # using augeas ron lensto inspe tht crontab 
  # http://augeas.net/docs/references/lenses/files/cron-aug.html    

end
