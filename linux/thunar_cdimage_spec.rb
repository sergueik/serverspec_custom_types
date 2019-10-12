require 'spec_helper'

# The .iso mount/unmount is not provided by default on XFCE
# https://forum.manjaro.org/t/thunar-iso-mount-unmount-is-missing/20168/13
context 'Disk Image Mounter' do
  context 'packages' do
    describe package 'gnome-disk-utility' do
      it { should be_installed }
    end
  end
  describe file "#{ENV['HOME']}/.config/mimeapps.list" do
    it { should be_file }
    its(:content) {should match Regexp.new('application/x-cd-image=([a-z0-9-]+.desktop;)*gnome-disk-image-mounter.desktop;') }
  end
end
