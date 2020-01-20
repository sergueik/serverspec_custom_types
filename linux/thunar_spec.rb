require 'spec_helper'
require 'fileutils'

context 'Thunar' do

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

  # The .iso mount/unmount is not provided by default ( specific to XFCE)
  # The PCManFM does not have this problem
  # https://forum.manjaro.org/t/thunar-iso-mount-unmount-is-missing/20168/13
  context 'Disk Image Mounter' do
    context 'packages' do
      describe package 'gnome-disk-utility' do
        it { should be_installed }
      end
    end
    describe file "#{ENV['HOME']}/.config/mimeapps.list" do
      it { should be_file } # created on first use
      its(:content) {should match Regexp.new('application/x-cd-image=([a-z0-9-]+.desktop;)*gnome-disk-image-mounter.desktop;') }
    end
  end

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

  # NOTE: removing tumbler package under Xubuntu likely lead to removal of xubuntu-desktop metapackage - varies with Ubuntu release
  context 'Tumbler Configuration' do
  
    rc_file = '/etc/xdg/tumbler/tumbler.rc'
    describe file rc_file do
      its(:content) { should_not match /Disabled=false/ }
    end
    describe command( <<-EOF
      grep -A4 '\[OdfThumbnailer\]' '#{rc_file}' | grep 'Disabled'
    EOF
    ) do
      its(:stdout) { should_not contain /Disabled=false/ }
    end
    # see also: https://github.com/pixelb/crudini/blob/master/crudini
    # see also: https://stackoverflow.com/questions/6318809/how-do-i-grab-an-ini-value-within-a-shell-script
    #
    # sed -nr "/^\'JPEGThumbnailer\]/ { :l /^Disabled' ]*=/ { s/.*=' ]*//; p; q;}; n; b l;}" /etc/xdg/tumbler/tumbler.rc
    # true
  
    describe command( <<-EOF
      grep -E '\\[[a-zA-Z0-9]+\\]' '#{rc_file}'
    EOF
    ) do
      [
        'JPEGThumbnailer',
        'PixbufThumbnailer',
        'RawThumbnailer',
        'CoverThumbnailer',
        'FfmpegThumbnailer',
        'GstThumbnailer',
        'FontThumbnailer',
        'PopplerThumbnailer',
        'OdfThumbnailer',
      ].each do |section|
        its(:stdout) { should contain "[#{section}]" }
      end
    end
  
  
    # TODO: add section discovery in before(:all)
  
    [
      # 'TypeNameOfPlugin',
      'JPEGThumbnailer',
      'PixbufThumbnailer',
      'RawThumbnailer',
      'CoverThumbnailer',
      'FfmpegThumbnailer',
      'GstThumbnailer',
      'FontThumbnailer',
      'PopplerThumbnailer',
      'OdfThumbnailer',
    ].each do |section|
      # NOTE: the following will break apart by section but loses section name
      # awk 'BEGIN{RS="\''a-zA-z0-9]+\]"} {print $1 " " $2}' /etc/xdg/tumbler/tumbler.rc
      # NOTE: for blank line the correct RS is the \n\n+ not the \n+
      # tac file | sed -n '1,/^$/{/./p}' | tac
      # see also: https://toster.ru/q/682041
      #
      describe command( <<-EOF
        grep -v '^ *#' '#{rc_file}' | awk 'BEGIN{RS="\\n\\n+"; OFS="\\n"} /#{section}/ {print $0}'
      EOF
      ) do
        its(:stdout) { should contain /Disabled=true/ }
      end
    end
    # TODO: define
    # check_exists(key_name)
    # check_has_property(key_name, key_property)
    # check_has_value(key_name, key_property, key_value)
  
    {
      'JPEGThumbnailer' => {
       #  empty
      } ,
      'CoverThumbnailer' => {
  	  'Locations' => '~/movies',
  	  'Priority' => 3,
      },
    }.each do |section,entries|
      describe command( <<-EOF
        grep -v '^ *#' '#{rc_file}' | awk 'BEGIN{RS="\\n\\n+"; OFS="\\n"} /#{section}/ {print $0}'
      EOF
      ) do
        entries.each do |key,value|
          # verbatim
  	    its(:stdout) { should contain "#{key}=#{value}" }
          # expression
  	    its(:stdout) { should match Regexp.new(Regexp.escape( "#{key}=#{value}" )) }
        end
      end
    end
  end
  
end
