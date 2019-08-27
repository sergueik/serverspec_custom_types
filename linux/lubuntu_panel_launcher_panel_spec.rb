require 'spec_helper'
#
# NOTE: window manager-specific
# origin: http://www.cyberforum.ru/shell/thread2492044.html
# see also :https://unix.stackexchange.com/questions/177386/how-can-i-add-applications-to-the-lxpanel-application-launch-bar-via-cli
context 'Lubuntu LXDE Launchers' do

  [
  'vivaldi-stable.desktop',
  'lxterminal.desktop',
  ].each do |desktop_file|
    descibe file "/usr/share/applications/#{desktop_file}" do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_mode '644' }
      # may need augeas lense to legitimately parse
      [
        '[Desktop Entry]'
        'Version=[\d.]+',
        'Name=',
        'GenericName=Web Browser',
        'Exec=/usr/bin/vivaldi-stable %U',
        'StartupNotify=(?:true|false)',
        'Terminal=false',
        'Icon=vivaldi',
        'Type=Application',
      #  'Actions=new-window;new-private-window;'
      ].each do |line|
        its(:content) { should match "^\s*" + Regexp.escape(line) }
      end
    end
  end
  describe file "#{env.fetch('HOME')}/.local/share/applications/" do
    it { should be_directory }
  end
  describe file "#{env.fetch('HOME')}/.config/lxpanel/Lubuntu/panels/panel" do
    it { should be_file }
    it { should be_owned_by env.fetch('USER') }
    it { should be_mode '644' }
    # may need augeas lense to legitimately parse
    # fragmens copied below
    # Global {
    #   edge=bottom
    #   allign=left
    #   margin=0
    #   widthtype=percent
    #   width=100
    #   height=24
    #   transparent=0
    #   tintcolor=#000000
    #   alpha=0
    #   setdocktype=1
    #   setpartialstrut=1
    #   usefontcolor=1
    #   fontcolor=#000000
    #   background=0
    #   backgroundfile=/usr/share/lxpanel/images/lubuntu-background.png
    #   iconsize=24
    # }
    # Plugin {
    #   type=launchbar
    #   Config {
    #     Button {
    #       id=pcmanfm.desktop
    #     }
    #     Button {
    #       id=lxde-x-www-browser.desktop
    #     }
    #     Button {
    #       id=firefox.desktop
    #     }
    #   }
    # }
    # Plugin {
    #   type=launchbar
    #   Config {
    #     Button {
    #       id=/usr/share/applications/lubuntu-logout.desktop
    #     }
    #   }
    # }
    # Plugin {
    #   type=xkb
    #   Config {
    #     Model=pc105
    #     LayoutsList=us,ru
    #     VariantsList=,
    #     ToggleOpt=grp:shift_caps_toggle,grp:lalt_lshift_toggle
    #     KeepSysLayouts=0
    #   }
    # }
  end
end
