require 'spec_helper'

context 'systemd path configuration' do
  # see also: https://www.putorius.net/systemd-path-units.html
  describe command('systemd-path') do
    its(:exit_status) { should eq 0 }
    {
      'user-binaries'        => '.local/bin',
      'user-library-private' => '.local/lib',
      'user-shared'          => '.local/share',
      'user-configuration'   => '.config',
      'user-runtime'         => '/run/user/\d+',
      'system-runtime-logs'  => '/run/log',
      'user-state-cache'     => '.cache',
      'user'                 => '',
    }.each do |key,path|
      homedir = '/home/' + ENV.fetch('LOGNAME','vagrant')
      full_path = if path =~ /^\//
        path
      else
        homedir + '/' + path
      end
      its(:stdout) { should match Regexp.new(full_path, Regexp::IGNORECASE) }
    end
  end

end


