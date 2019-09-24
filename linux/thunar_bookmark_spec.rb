require 'spec_helper'

# https://unix.stackexchange.com/questions/87687/how-to-create-folder-shortcuts-in-file-manager
context 'Folder Shortcut spec' do
  unix_user = 'sergueik'
  windows_account = 'Serguei'
  disk_name = 'Windows8_OS'
  windows_desktop_shortcut = "/media/#{unix_user}/#{disk_name}/Users/#{windows_account}/Desktop"
  describe file "/home/#{unix_user}/.config/gtk-3.0/bookmarks" do
    it { should be_file }
    its(:content) { should contain "file://#{windows_desktop_shortcut}" }
  end
end