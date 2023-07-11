require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

# used by e.g. chunchbang linux 
# https://en.wikipedia.org/wiki/CrunchBang_Linux
context 'Openbox' do
  context 'packages' do
    %w|dmenu openbox obmenu conky terminator tint2|.each do |name|
      describe package name do
        it { should be_installed }
      end
    end
  end	  
  context 'configurations' do
    user = 'sergueik'
    %w|menu.xml rc.xml autostart|.each do |name|
      describe file "/home/#{user}/.config/openbox/#{name}" do
        it { should be_file }
      end
    end
    context 'rc' do
      describe file "/home/#{user}/.config/openbox/rc.xml" do
        it { should be_file }
        its(:content) { should contain 'openbox_config xmlns="http://openbox.org/3.4/rc"' }
      end
    end

    context 'menu' do
      describe file "/home/#{user}/.config/openbox/menu.xml" do
        it { should be_file }
        its(:content) { should contain 'openbox_menu xmlns="http://openbox.org/"' }
      end
      context "'Exit' menu item" do
	# must contain exit item      
        command = 'cb_exit'
        describe command(<<-EOF
          xmllint --xpath '/*[local-name() = "openbox_menu"]/*[local-name()="menu"][1]/*[local-name() = "item"]/*[local-name()="action"]/*[local-name()="command"][contains(text() , "#{command}")]' '/home/#{user}/.config/openbox/menu.xml'
        EOF
        ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should contain "#{command}" }
          its(:stderr) { should be_empty }
        end
      end
      context 'sub menus' do
	# defaul mouse menu has several, possibly nested, submenus
        describe command(<<-EOF
          xmllint --xpath 'count(//*[local-name()="menu"][@label])' '/home/#{user}/.config/openbox/menu.xml'
        EOF
        ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match /^[1-9][0-9]*$/ }
          its(:stderr) { should be_empty }
        end
      end
    end
  end
end
