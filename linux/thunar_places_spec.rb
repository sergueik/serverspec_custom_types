require 'spec_helper'
require 'fileutils'

context 'Thunar Places' do

  # https://docs.xfce.org/xfce/thunar/the-file-manager-window
  # https://ubuntuforums.org/showthread.php?t=1346162
  # for gtk 2.x /home/$USER/.gtk-bookmarks
  # for gtk 3.x /home/$USER/.config/gtk-3.0/bookmarks
  user = ENV.fetch('USER','vagrant')
  describe file("/home/#{user}/.config/gtk-3.0/bookmarks") do
    it { should be_file }
    it { should be_mode 664 } # NOTE: no leading zero
    %w|
      Videos
      Music
    |.each do|place|
      its(:content) { should contain "file:///media/#{user}/data/#{place}" }
    end
  end
end

