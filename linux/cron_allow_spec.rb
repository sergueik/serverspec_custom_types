# https://access.redhat.com/solutions/1535573
# https://www.thegeekdiary.com/unix-linux-how-crontab-validates-the-access-based-on-the-cron-allow-and-cron-deny-files/

context 'Allowed users' do
  cron_allow =
  if ['redhat', 'debian', 'ubuntu'].include?(os[:family])
    # standard Linux
    '/etc/cron.allow'
  else
    # non-standard location on Sun
    # https://docs.oracle.com/cd/E19253-01/817-0403/sysrescron-23/index.html
    '/etc/cron.d/cron.allow'
  end
  describe file cron_allow do
    it { should be_file }
  end
end
