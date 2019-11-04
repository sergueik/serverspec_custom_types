require 'spec_helper'

# NOTE: removing tumbler package under Xubuntu likely lead to removal of xubuntu-desktop metapackage - varies with Ubuntu release
context 'Tumbler Configuration' do

  rc_file = '/etc/xdg/tumbler/tumbler.rc'
  describe file rc_file do
    its(:content) { should_not match /Disabled=false/ }
  end
  describe command( <<-EOF
    grep -A4 '\[OdfThumbnailer\]' #{rc_file} | grep Disabled
  EOF
  ) do

    its(:stdout) { should_not contain /Disabled=false/ }
  end
  # see also: https://github.com/pixelb/crudini/blob/master/crudini
  # see also: https://stackoverflow.com/questions/6318809/how-do-i-grab-an-ini-value-within-a-shell-script
  #
  # sed -nr "/^\[JPEGThumbnailer\]/ { :l /^Disabled[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" /etc/xdg/tumbler/tumbler.rc
  # true
end
