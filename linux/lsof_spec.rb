require 'spec_helper'

# https://stackoverflow.com/questions/43845316/x11vnc-xopendisplay-failed
# https://unix.stackexchange.com/questions/196677/what-is-tmp-x11-unix

context 'X11 display do' do
  begin
  uid = ENV.fetch('UID')
  rescue => e
    # keyError:
    # key not found: "UID"
    uid = %x/ id -u  | tr -d '\\n'/
  end
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
