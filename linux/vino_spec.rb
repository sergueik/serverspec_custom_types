require 'spec_helper'

context 'xFCE Session and Startup desktop launchers' do
  # will it be the correct user?
  user = ENV.fetch('USER')
  launcher_dir = "/home/#{user}/.config/autostart"
  lightdm_dir = '/usr/share/lightdm/lightdm.conf.d'
  context 'Vino launcher' do
    # https://askubuntu.com/questions/83824/how-can-i-start-a-vnc-server-before-log-on
    # https://askubuntu.com/questions/530072/how-to-auto-login-in-xubuntu
    describe file("#{lightdm_dir}/60-xubuntu.conf") do
      it { should be_file }
      [
        '[Seat:*]',
      ].each do |section|
        its(:content) { should contain section }
      end
      {
        'user-session'   => 'xubuntu',
        'autologin-user' => user
      }.each do |setting,value|
        its(:content) { should contain "#{setting}=#{value}" }
      end
    end
    describe file("#{launcher_dir}/vino-server.desktop") do
      it { should be_file }
      # type
      [
        '[Desktop Entry]',
      ].each do |section|
        its(:content) { should contain section }
      end
      # probaly not every setting is required
      {
        'Encoding'      => 'UTF-8',
        'Version'       => '0.9.4',
        'Type'          => 'Application',
        'Name'          => 'vino-server',
        'Comment'       => 'VNC Server',
        'Exec'          => '/usr/lib/vino/vino-server',
        'OnlyShowIn'    => 'XFCE;',
        'StartupNotify' => 'false',
        'Terminal'      => 'false',
        'Hidden'        => 'false',
      }.each do |setting,value|
        its(:content) { should contain "#{setting}=#{value}" }
      end
    end
  end
  context 'Blueman Bluetooth Manager applet' do
    desktop_launcher_file = "#{launcher_dir}/blueman.desktop"
    describe file(desktop_launcher_file) do
      it { should be_file }
      # #let or #subject called without a block (RuntimeError)
      # subject { $stderr.puts self }
      $stderr.puts "'#{self.class.name.split('::').last}'" # 'Class'
      $stderr.puts "'#{self.to_s.split('::').last}'" # 'FileHomeRootConfigAutostartBluemanDesktop'
      its(:content) { should contain '[Desktop Entry]' } # TODO: first line
      describe command("head -1 #{desktop_launcher_file} | grep -P '\\[Desktop Entry\\]'") do
        its(:stdout) { should contain '[Desktop Entry]' }
      end
      # Removed from Application Autostart is simply Hidden at the xFCE launcher
      {
        'Hidden' => 'true',
      }.each do |setting,value|
        its(:content) { should contain "#{setting}=#{value}" }
      end
    end
  end
end
