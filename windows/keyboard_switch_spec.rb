if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end



# based on: https://winaero.com/change-hotkeys-switch-keyboard-layout-windows-10
# [HKEY_CURRENT_USER\Keyboard Layout\Toggle]
# "Hotkey"="3"
# "Language Hotkey"="3"
# "Layout Hotkey"="1"
# the values meaning of the:
# '1' - Key Sequence enabled; use LEFT ALT+SHIFT to switch between locales.
# '2' - Key Sequence enabled; use CTRL+SHIFT to switch between locales.
# '3' - Key Sequences disabled.
# '4' - The grave accent key (`), located below Esc toggles input locales.

# verified on Windows 10 x64 RU 19041.264 and Windows 7 EN and RU 7601
#
# to open "Text Services and Input Languages" panel, but with the wrong tab, need additional arguments:
# rundll32.exe Shell32.dll,Control_RunDLL input.dll,,{C07337D3-DB2C-4D0B-9A93-B722A6C106E2}
# see also: https://ss64.com/nt/rundll32.html 
# NOTE: on localized versions of Windows the "Switch Input Language" group may remain unassigned yet the "Switch Keyboard Layout" may be present and its default value on vanilla system is unknown. 
# On EN Windows with extra languages installed, need to set the "Language Hotkey" to 1/3 to enable/disable

# On non-EN Windows with EN added as keyboard layout, need to set the "Language Hotkey" to 3 then set the "Layout Hotkey" to 3/1 to disable/enable

# no logoff required after enable/disable programmatically
# see also: https://superuser.com/questions/1450202/disable-windows-10-language-popup/1763358#1763358
# about Windows 10 specific annoying lannguage switch notificstion
# new-itemproperty -path "HKCU:\Keyboard Layout\Toggle" -name 'Layout Hotkey' -Value 1
# set-itemproperty -path "HKCU:\Keyboard Layout\Toggle" -name 'Layout Hotkey' -Value 1
# set-itemproperty -path "HKCU:\Keyboard Layout\Toggle" -name 'Layout Hotkey' -Value 3

context 'Language' do
  describe command(<<-EOF
    $data = @{
    'Language Hotkey' = $null;
    'Hotkey' = $null;
    'Layout Hotkey' = $null;
    };
    # NOTE: An error occurred while enumerating through a collection: 
    # Collection was modified; 
    # enumeration operation may not execute.
    # this will occur even if assign $data.Keys to separate variable
    # $keys = $data.Keys;
    $keys = @();
    $data.Keys | foreach-object {
      $name = $_ 
      $keys += $name
    };
    $keys | foreach-object { 
      $name = $_ 
      $data[$name] = (get-itemproperty -path "HKCU:\\Keyboard Layout\\Toggle" -name $name) | select-object -expandproperty $name
    };
    write-output $data | convertto-json
    EOF
  ) do
    [
      'Language Hotkey',
      'Layout Hotkey',
      'Hotkey',
    ].each do |key|
      its(:stdout) { should match Regexp.new(/"#{key}":\s+"[1-4]"/ ) }
    end
  end
end
