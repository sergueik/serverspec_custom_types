require 'spec_helper'

context 'system limit' do
  context 'configuration' do
    limits_dir = '/etc/security/limits.d'
    describe file(limits_dir) do
      it { should be_directory }
    end
    # some security requirements enforce removal of limits.conf
    describe file('/etc/security/limits.conf') do
      it { should_not be_present }
    end
    [
    '20-limits',
    ].each do |conf_file|
      describe file("#{limits_dir}/#{conf_file}.conf") do
        it { should be_file }
        its(:content) { should match /(?:\w+)\s+(?:(\-|soft|hard))\s+(?:(core|nproc|nofile|nss))\s+(?:\d+)$/ }
      end
    end
  end

  context 'Vanilla "/etc/security/limits.conf" configuration' do
    default_config = '/etc/security/limits.conf'
    describe file(default_config) do
      it { should be_file }
    end
    # the default limits.conf is full of comments but has no limit statements
    describe command("grep -vE '^ *#' '#{default_config}' | grep -Es '[a-z]'") do
      its(:stdout) { should be_empty }
    end
  end

  context 'inspection' do
    # origin: https://unix.stackexchange.com/questions/345595/how-to-set-ulimits-on-service-with-systemd
    # https://stackoverflow.com/questions/21752067/counting-open-files-per-process
    jar_filename = 'org.eclipse.equinox.launcher'
    max_open_files = 1048576
    # hack to prevent grep from finding itself
    jar_filename_changed = jar_filename.gsub(/^(\w)/,'[\1]')
    describe command( <<-EOF
      cat /proc/$(ps ax | grep "#{jar_filename_changed}"|head -1 | awk '{print $1}')/limits
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new("Max open files *#{max_open_files} *#{max_open_files} *files", Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end
  # alternatively
  context 'Process limits configuration' do
    command_fragment = 'org.apache.catalina.startup.Bootstrap star[t]'
    describe command(<<-EOF
      COMMAND_FRAGMENT='#{command_fragment}'
      PID=$(ps ax -opid,cmd| grep "${COMMAND_FRAGMENT}"|cut -d' ' -f 1,2 | sed 's|  *||g')
      cat /proc/$PID/limits
    EOF
    ) do
      its(:stderr) { should be_empty }
      [
        'Limit                     Soft Limit           Hard Limit           Units',
        'Max processes             3888                 3888                 processes',
        'Max open files            4096                 4096                 files',
        'Max locked memory         65536                65536                bytes',
      ].each do |line|
        its(:stdout) { should contain line }
      end
    end
  end
end
