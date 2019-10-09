require 'spec_helper'


context 'Blueman disabled from autostart' do
  # NOTE: package may be completely removed or not
  context 'Packages' do
    describe package 'blueman' do
      it { should_not be_installed }
    end
  end
  # based on:https://askubuntu.com/questions/67758/how-can-i-deactivate-bluetooth-on-system-startup
  context 'State' do
    describe command( <<-EOF
      for ID in $(rfkill list | grep -i 'bluetooth' | grep -E '^[0-9]+:'| cut -d: -f1) ; do
        rfkill list $ID
      done
    EOF
    ) do
      its(:stdout) { should contain 'Soft blocked: yes' }
      its(:exit_status) { should eq 0 }
    end
  end
  # TODO: examine /etc/xdg/autostart/blueman.desktop and $HOME/.config/autostart/print-applet.desktop
  # https://bbs.archlinux.org/viewtopic.php?id=210844
  # and services
  # https://ubuntu-mate.community/t/turn-off-bluetooth-by-default/12979/7
end
