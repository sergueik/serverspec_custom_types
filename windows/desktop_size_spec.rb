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
    # Registry check 'Control Panel\Appearance and Personalization\Display' 
    # Make text and other items on the desktop smaller and larger information
    # - will work for pre-10 Windows releases
    # based on: https://stackoverflow.com/questions/32607468/get-scale-of-screen
    #
    # see also: https://stackoverflow.com/questions/13228185/how-to-configure-an-app-to-run-correctly-on-a-machine-with-a-high-dpi-setting-e/13228495#13228495
    # about DpiAwareness
    # and https://docs.microsoft.com/en-us/uwp/api/Windows.Graphics.Display.DisplayProperties
    # about DisplayProperties
    # https://docs.microsoft.com/en-us/uwp/api/windows.graphics.display.displayinformation
    # about DisplayInformation
    display_scale = '125'
    describe command(<<-EOF
      $hive ='HKCU:'
      $path = 'Control Panel/Desktop'
      $name = 'LogPixels'
      $registry_value = 96.0
      # https://stackoverflow.com/questions/27642169/looping-through-each-noteproperty-in-a-custom-object
      $o = get-itemproperty -path ('{0}/{1}' -f $hive,$path) -name $name -erroraction 'SilentlyContinue'
      $registry_value = $o.PSObject.Properties |
                        where-object {$_.Name -eq $name } |
                        foreach-object { write-output $_.Value }
      $display_scale = [int]((([float]$registry_value + 0.00 )/96)* 100)  # e.g. 125
      # one cannot print string to STDOUT for the sake of available subset of RSPec mathers
      # so print different to STDERR and STDOUT 
      # https://relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
      # NOTE: format errors become Microsoft.PowerShell.Commands.WriteErrorException 
      # NOTE: some  discrepncy between running this as a standlaone PS1 snippet and serverspec
      # 
      # <?xml version="1.0"?>
      # <Objs xmlns="http://schemas.microsoft.com/powershell/2004/04" Version="1.1.0.1">
      #   <Obj S="progress" RefId="0">
      #     <TN RefId="0">
      #       <T>System.Management.Automation.PSCustomObject</T>
      #       <T>System.Object</T>
      #     </TN>
      #     <MS>
      #       <I64 N="SourceId">1</I64>
      #       <PR N="Record">
      #         <AV>Preparing modules for first use.</AV>
      #         <AI>0</AI>
      #         <Nil/>
      #         <PI>-1</PI>
      #         <PC>-1</PC>
      #         <T>Completed</T>
      #         <SR>-1</SR>
      #         <SD> </SD>
      #       </PR>
      #     </MS>
      #   </Obj>
      # </Objs>
      # 
      $error_message = ('Display scale: {0}' -f $display_scale ) 
      write-error $error_message -erroraction 'SilentlyContinue'
      [System.Console]::Error.WriteLine($error_message)
      write-output $display_scale
    EOF
    ) do
      its (:stderr) { should match /Dislay scale: \d+/ }
	  # https://relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
      its (:stdout) { should be >= display_scale }
      # The following will raise NoMethodError: undefined method `call' for nil:NilClass
      # its (:stdout) { should satisfy { |val| $stderr.puts val; val.chomp! =~ Regexp.new(display_scale) } }
    end
  end
end

