require 'spec_helper'

context 'Standard' do
  describe package 'vino' do
    it { should be_installed }
  end
  describe process 'vino-server' do
    it { should be_running }
  end
  vnc_tcp_port = 5900
  describe port vnc_tcp_port do
    it { should be_listening.with 'tcp' }
    it { should be_listening.with 'tcp6' }
  end
  context 'vnc xfce process tree' do
    describe command( <<-EOF
      PID=$(ps ax -ocmd,args,pid,ppid| grep vin[o] |awk '{print $NF}')
      ps -P $PID
      ps -wP $PID| grep -o 'xfce4-session'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      its(:stdout) { should contain 'xfce4-session' }
    end
  end
  # NOTE: not all settings are present on a vanilla ubuntu system
  context 'application configuration' do
    describe command 'gsettings list-schemas' do
      %w|
        com.ubuntu.sound
        com.ubuntu.user-interface
        org.gnome.Charmap
        org.gnome.desktop.interface
        org.gnome.desktop.notifications
      |.each do |key|
        its(:stdout) { should contain key }
      end
    end	
    scheme = 'org.gnome.desktop.interface'
    describe command "settings list-keys #{scheme}" do
      %w|
        document-font-name
        gtk-color-scheme
        icon-theme
        monospace-font-name
        scaling-factor
        toolbar-style
      |.each do |key|
        its(:stdout) { should contain key }
      end
    end	
    scheme = 'org.gnome.Vino'
    describe command "gsettings list-keys #{scheme}" do
      %w|
        notify-on-connect
        alternative-port
        disable-background
        use-alternative-port
        icon-visibility
        use-upnp
        view-only
        prompt-enabled
        disable-xdamage
        authentication-methods
        network-interface
        require-encryption
        mailto
        lock-screen-on-disconnect
        vnc-password
      |.each do |key|
        its(:stdout) { should contain key }
      end
    end
    # NOTE: omitted sudo
    describe command( <<-EOF
      echo $(gsettings get org.gnome.Vino vnc-password ) | tr -d "'" | base64 -d - > /dev/null
    EOF
    ) do
        its(:exit_status) { should eq 0 }
    end

    # vino-preference needs a display to list configuration details
    # see also
    # https://www.xmodulo.com/enable-configure-desktop-sharing-linux-mint-cinnamon-desktop.html
    # https://hex.ro/wp/blog/fedora-20-remote-desktop-with-tightvnc-viewer-from-windows-7/
    # https://wpcademy.com/how-to-install-vnc-server-on-ubuntu-18-04-lts/
    # https://stackoverflow.com/questions/18878117/using-vagrant-to-run-virtual-machines-with-desktop-environment
    # on bionic 18.04 comes unconfigured and observed when connecting:
    # error in  tightvnc viewer: no security types supported.
    # server sent security types but we do not support any of them
    {
      'vnc-password' => '[a-zA-Z0-9]+=*$', #  $(echo -n "#{password}"|base64)
      'network-interface' => '',
      'require-encryption' => false,
      'enabled' => true,
      'authentication-methods' => "\\['vnc'\\]",
      'notify-on-connect' => true,
      'prompt-enabled' => true, # can be configured to false
    }.each do |key,value|
      describe command "gsettings get org.gnome.Vino #{key}" do
        its(:stderr) { should_not contain "No such schema 'org.gnome.Vino'" }
        if value.eql? ''
          its(:stdout) { should contain '' }
        else
          its(:stdout) { should contain Regexp.new(value.to_s) }
        end
      end
    end
    # see also: http://www.softpanorama.org/Xwindows/VNC/Vino/activating_vino_from_command_line.shtml
  end
end
context 'xFCE Session and Startup desktop launchers' do
  # will it be the correct user?
  user = ENV.fetch('USER')
  launcher_dir = "/home/#{user}/.config/autostart"
  lightdm_dir = '/usr/share/lightdm/lightdm.conf.d'
  context 'Vino launcher' do
    # https://askubuntu.com/questions/83824/how-can-i-start-a-vnc-server-before-log-on
    # https://askubuntu.com/questions/12206/how-do-i-start-the-vnc-server
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
      # https://wiki.archlinux.org/index.php/Vino
      # probaly not every setting is required
      {
        'Encoding'      => 'UTF-8',
        'Version'       => '0.9.4',
        'Type'          => 'Application',
        'Name'          => 'vino-server',
        'Comment'       => 'VNC Server',
        'Exec'          => '/usr/lib/vino/vino-server',
        # 'NoDisplay'     => true, # TODO: limit this test to headless hosts
        'OnlyShowIn'    => 'XFCE;',
        'StartupNotify' => 'false',
        'Terminal'      => 'false',
        'Hidden'        => 'false',
      }.each do |setting,value|
        its(:content) { should contain "#{setting}=#{value.to_s}" }
      end
    end
  end
  context 'Blueman Bluetooth Manager applet' do
    desktop_launcher_file = "#{launcher_dir}/blueman.desktop"
    describe file desktop_launcher_file  do
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
