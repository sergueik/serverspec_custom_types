require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Sockets' do
  # https://wiki.archlinux.org/index.php/Systemd/User
  # see also: https://askubuntu.com/questions/1120023/how-to-use-systemd-notify
  # https://unix.stackexchange.com/questions/162900/what-is-this-folder-run-user-1000
  begin
    uid = ENV.fetch('UID')
    user = ENV.fetch('USER')
  rescue => e
    # keyError:
    # key not found: "UID"
    uid = %x/ id -u  | tr -d '\\n'/
    uid_command = "id -u | tr -d '\\n'"
    uid = command(uid_command).stdout
    whoami_command = "whoami | tr -d '\\n'"
    user = command(whoami_command).stdout
  end

  context 'User level systemd units' do
    %w|
      private
      notify
    |.each do |socket_filename|
      describe file "/run/user/#{uid}/systemd/#{socket_filename}" do
        it do
          should be_socket
          should be_mode 775
        end
      end
    end
    describe command(<<-EOF
      find /run/user/$(id -u)/systemd -type s
    EOF

    ) do
      # NOTE: no #{} interpolation inside %w||
      # hence the %w|/run/user/#{uid}/systemd/private| will not work as expected
      [
        "/run/user/#{uid}/systemd/private",
        "/run/user/#{uid}/systemd/notify"
      ].each do |socket_filepath|
        its(:stdout) { should contain socket_filepath }
      end
    end
  end
  # See also:
  # linux desktop application autostart https://habr.com/ru/company/ruvds/blog/583328/
  # (in Russian)
  # NOTE: the gnome-shell-x11.service user systemd service exists only for Gnome - none under XFCE or LXDE 
  context 'Sockets' do
    %w|
      notify
      private
    |.each |socket_filename| do
      describe file( "/run/user/#{uid}/systemd/#{socket_filename}") do
        it { should be_socket }
        it { should be_mode 775 }
      end
      describe command( <<-EOF
        lsof /run/user/$(id -u)/systemd/#{socket_filename}
      EOF
      ) do
        its(:exit_status) { should eq 0 }
      end
    end
      describe command( <<-EOF
        lsof -F cputL /run/user/$(id -u)/systemd/#{socket_filename}
      EOF
      ) do
        its(:stdout) { should contain 'c' + 'systemd' }
        its(:stdout) { should contain 't' + 'unix' }
        its(:stdout) { should contain 'L' + user }
        # the file descriptor is always selected
        its(:stdout) { should match /f\d+$/ }
        its(:stdout) { should contain 'u'+ uid.to_s }
      end
    end
  end

  # https://stackoverflow.com/questions/43845316/x11vnc-xopendisplay-failed
  # https://unix.stackexchange.com/questions/196677/what-is-tmp-x11-unix
  context 'X11 display do' do
    describe command(<<-EOF
      find /tmp/.X11-unix/ -type s -name 'X*' | xargs -IX lsof -U X 2>/dev/null
    EOF

    ) do
      %w|COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME|.each do |header|
        its(:stdout) { should contain header }
      end

      [
        'type=STREAM',
        'type=DGRAM',
        "/run/user/#{uid}/systemd/notify",
        "/run/user/#{uid}/systemd/private"
      ].each do |keyword|
        its(:stdout) { should contain keyword }
      end
      its(:stderr) { should be_empty}
    end
    # https://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
    socket_file = %x(find /tmp/.X11-unix/ -type s -name 'X*' | tr -d '\\n')
    describe command("echo -n \"'#{socket_file}'\"") do
      its(:stdout) { should contain 'tmp' }
      its(:stdout) { should_not match /.*\n.*/m }
    end
    # some situations td does not honor -d flag. keeping a longer version for those
    socket_file = %x(find /tmp/.X11-unix/ -type s -name 'X*' | tr '\\n' ' ' | sed 's/ $//')
    describe command("echo -n \"'#{socket_file}'\"") do
      its(:stdout) { should contain 'tmp' }
      its(:stdout) { should_not match /.*\n.*/m }
    end
    describe file(socket_file) do
      it { should exist }
      it { should be_socket }
    end
    # TODO: sample vnc command with a wrong -display

  end
end
