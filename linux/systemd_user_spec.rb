require 'spec_helper'

# https://wiki.archlinux.org/index.php/Systemd/User
# https://www.brendanlong.com/systemd-user-services-are-amazing.html
# https://askubuntu.com/questions/676007/how-do-i-make-my-systemd-service-run-via-specific-user-and-start-on-boot
# https://daniel.perez.sh/blog/2018/user-systemd/
# https://unix.stackexchange.com/questions/415357/cannot-enable-user-service-failed-to-get-d-bus-connection-connection-refused
# https://bugs.centos.org/view.php?id=8767
# https://pbrisbin.com/posts/systemd-user/
# https://answers.launchpad.net/ubuntu/+source/systemd/+question/287454
    # elementary when user is logged with X. 
    # Failing with various dbus errors in console
    # mkdir -p ~/.config/systemd/user
    # cd ~/.config/systemd/user
    # cat <<EOF> ~/.config/systemd/user/sample_service.service
    # [Unit]
    # Description=[Service description]
    #
    # [Service]
    # Type=simple
    # StandardOutput=journal
    # ExecStart=/usr/bin/perl
    #
    # [Install]
    # WantedBy=default.target
    # EOF
    # systemctl --user enable sample_service
    # # Created symlink from /home/sergueik/.config/systemd/user/default.target.wants/sample_service.service to /home/sergueik/.config/systemd/user/sample_service.service.
    # systemctl --user start sample_service
    # TODO: Failed to connect to bus: No such file or directory
    # apt-get install dbus-user-session libpam-systemd
    # A reboot is required to replace the running dbus-daemon.
    # systemctl list-units | grep -i bus
    # dbus.service  
    #      loaded active running   D-Bus System Message Bus
    #
    # Failed to start dbus.service: Operation refused, unit dbus.service may be requested by dependency only.
    #
    # systemctl --user status -l sample_service
    # ● sample_service.service - [Service description]
    #    Loaded: loaded (/home/sergueik/.config/systemd/user/sample_service.service; e
    #    Active: inactive (dead) since Fri 2019-12-20 17:28:39 EST; 4s ago
    #   Process: 3670 ExecStart=/usr/bin/perl (code=exited, status=0/SUCCESS)
    #  Main PID: 3670 (code=exited, status=0/SUCCESS)
    #
    # systemd[1614]: Started [Service description].
    #
    # Failed to get D-Bus connection: Unable to autolaunch a dbus-daemon without a $DISPLAY for X11
    # https://bbs.archlinux.org/viewtopic.php?id=157545
    # export DBUS_SESSION_BUS_ADDRESS=/run/user/$(id -u)/dbus/user_bus_socket
    # Failed to get D-Bus connection: Address does not contain a colon
    # export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/dbus/user_bus_socket
    # systemctl --user enable sample_service
    # Failed to get D-Bus connection: Failed to connect to socket /run/user/1003/dbus/user_bus_socket: No such file or director
    # dbus-daemon --session --print-address 1
    # export DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-oS71hPJo0f
    # export DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-oS71hPJo0f
    # sample_user@localhost:~$ systemctl --user start sample_service    
    #              Failed to connect to bus: Connection refused
    # ls -l /run/user/1000/
    # total 0
    # srw-rw-rw- 1 vagrant vagrant  0 Dec 21 10:10 bus
    # drwxr-xr-x 2 vagrant vagrant 80 Dec 21 10:10 systemd

    # systemctl --user enable sample_service
    #    Activating service name='org.freedesktop.systemd1'
    # ** (process:4768): CRITICAL **: Unable to acquire bus name 'org.freedesktop.systemd1'.  Quitting.
    # Activated service 'org.freedesktop.systemd1' failed: 
    # Process /usr/lib/x86_64-linux-gnu/systemd-shim exited with status 1
    # https://serverfault.com/questions/892465/starting-systemd-services-sharing-a-session-d-bus-on-headless-system
    # https://packages.ubuntu.com/bionic/dbus-user-session
    # https://packages.ubuntu.com/xenial-updates/dbus-user-session
    # https://packages.ubuntu.com/xenial/dbus-user-session

context 'per-user systemd instance test' do
  unit = 'httpd'
  user = 'sample_user'
  systemd_user_dir = "/home/#{user}/.config/systemd/user"

  describe file "#{systemd_user_dir}/user-applications.target" do
    it { should be_file }
    it { should_not be_linked_to('/dev/null') }
    its(:content) { should match /^Requires=default.target/ }
  end	
    #  [Unit]
    #  Description=User Applications
    #  Requires=default.target
    #  After=default.target
  describe file "#{systemd_user_dir}/#{unit}.service" do
    it { should_not be_symlink }
    it { should_not be_linked_to '/dev/null' }
  end	
    #
    # [Unit]
    # AssertPathExists=/home/ghost/ghost
    #
    # [Service]
    # WorkingDirectory=/home/ghost/ghost
    # Environment=GHOST_NODE_VERSION_CHECK=false
    # ExecStart=/usr/bin/npm start --production
    # Restart=always
    # PrivateTmp=true
    # NoNewPrivileges=true
    #
    # [Install]
    # WantedBy=default.target
  describe command(<<- EOF
    ssh #{user}@$(hostname -f) systemctl --user import-environment VAR_TO_EXPOSE
    ssh #{user}@$(hostname -f) systemctl --user start user-applications.target
  EOF
  ) do
    its (:exit_status) { should eq 0 }
  end	
end

