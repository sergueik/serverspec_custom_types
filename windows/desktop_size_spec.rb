require_relative '../windows_spec_helper'

context 'Desktop Window Size' do
  context 'Windows Forms' do
    describe command(<<-EOF
      [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
      $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
      $primaryScreen | select-object -Expandproperty 'Bounds' |
      select-object -property Width,Height |
      format-list
    EOF
    ) do
      {
        'Width' => 1920,
        'Height' => 1080,
      }.each do |key,val|
        its (:stdout) { should match Regexp.new(key + '\s*:\s+' + val.to_s) }
      end
    end
    describe command(<<-EOF
      [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

      $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
      $primaryScreen | select-object -Expandproperty 'WorkingArea' |
      select-object -property Width,Height |
      format-list
    EOF
    ) do
      {
        'Width' => 1920,
        'Height' => 1032,
      }.each do |key,val|
        its (:stdout) { should match Regexp.new(key + '\s*:\s+' + val.to_s) }
      end
    end
  end
  context 'WMI information' do
    # NOTE: some, e.g. VirtualBox Graphics Adapter may not even filll the data
    describe command(<<-EOF
      get-wmiobject -class 'Win32_VideoController' |
      where-object { $_.Availability  -eq '3' } |
      select-object -first 1 |
      select-object -property CurrentHorizontalResolution, CurrentVerticalResolution,VideoModeDescription,Caption,PNPDeviceID |
      format-list
    EOF
    ) do
      {
        'CurrentHorizontalResolution' => 1920,
        'CurrentVerticalResolution'   => 1080,
      }.each do |key,val|
        its (:stdout) { should match Regexp.new(key + '\s*:\s+' + val.to_s) }
      end
    end
  end
  context 'Display Scaling' do
    # Registry check - will work for older Windows releases
    # reflexts 'Control Panel\Appearance and Personalization\Display' Make text and other items on the desktop smaller and larger information
    # based on: https://stackoverflow.com/questions/32607468/get-scale-of-screen
    #
    # see also: https://stackoverflow.com/questions/13228185/how-to-configure-an-app-to-run-correctly-on-a-machine-with-a-high-dpi-setting-e/13228495#13228495
    # about DpiAwareness
    # and https://docs.microsoft.com/en-us/uwp/api/Windows.Graphics.Display.DisplayProperties
    # about DisplayProperties
    # https://docs.microsoft.com/en-us/uwp/api/windows.graphics.display.displayinformation
    # about DisplayInformation
    display_scale = '1.25'
    describe command(<<-EOF
      $hive ='HKCU:'
      $path = 'Control Panel/Desktop'
      $name = 'LogPixels'
      $currentDPI = $null
      $currentDPI = Get-ItemProperty -Path ('{0}/{1}' -f $hive,$path) -Name $name -ErrorAction 'SilentlyContinue'
      # https://stackoverflow.com/questions/27642169/looping-through-each-noteproperty-in-a-custom-object
      # foreach ($noteProperty in $currentDPI) { write-Host $noteProperty }
      #
      # @{LogPixels=120; PSPath=Microsoft.PowerShell.Core\\Registry::HKEY_CURRENT_USER\\Control Panel\\Desktop; PSParentPath=Microsoft.PowerShell.Core\\Registry::HKEY_CURRENT_USER\\Control Panel; PSChildName=Desktop; PSDrive=HKCU; PSProvider=Microsoft.PowerShell.Core\\Registry}
      # $currentDPI | get-member -type NoteProperty -name 'LogPixels' | select-object -expandProperty Definition | format-list
      # System.Int32 LogPixels=120
      #
      $currentDPIValue = $currentDPI.PSObject.Properties | where-object {$_.Name -eq $name }| foreach-object { write-output $_.Value }
      # Method invocation failed because [System.Management.Automation.PSObject] does not contain a method named 'op_Division'.
      if ($currentDPIValue -eq $null)  { $currentDPIValue = 96.0 }
      if ($currentDPI -eq $null)  { $currentDPI = 96 } else { $currentDPI = $currentDPI.LogPixels }
      $display_scale = ($currentDPIValue + 0.00 )/96
      write-output $display_scale
    EOF
    ) do
      # https://relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
      its (:stdout) { should be >= display_scale }
      # The following will raise NoMethodError: undefined method `call' for nil:NilClass
      # its (:stdout) { should satisfy { |val| $stderr.puts val; val.chomp! =~ Regexp.new(display_scale) } }
    end
  end
end

