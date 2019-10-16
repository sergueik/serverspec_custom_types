require 'spec_helper'

# see also: https://askubuntu.com/questions/444855/is-it-possible-to-verify-grub-installation-without-rebooting
# For inspection where the grub configuration is actually located, see 
# https://sourceforge.net/projects/bootinfoscript/
# NOTE: quite big
context 'Valid Grub config spec' do
  describe command(<<-EOF
    BOOT=$(mount | grep ' / ' | awk '{print $1}')
    BLKID=$(blkid -p $BOOT | awk '{print $2}' | sed 's|UUID=||' | tr -d '"')
    grep -i $BLKID /boot/grub/grub.cfg | grep $(uname -r) | grep menuentry
  EOF
  ) do
    its(:stdout) { should contain 'Linux' }
    its(:exit_status) { should eq 0 }
  end
end