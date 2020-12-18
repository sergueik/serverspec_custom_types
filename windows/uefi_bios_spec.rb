require_relative '../windows_spec_helper'

context 'Boot to UEFI Mode or legacy BIOS mode' do
  # origin: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-to-uefi-mode-or-legacy-bios-mode#uefi-and-bios-modes-in-winpe
  # NOTE: on older releases the recommended reg.exe command 
  # reg.exe query HKLM\System\CurrentControlSet\Control /v PEFirmwareType
  # will simply fail because there was no value
  describe command(<<-EOF

    $hive = 'HKLM:'
    $path = '/System/CurrentControlSet/Control'
    $name = 'PEFirmwareType'
    
    # NOTE: need to test  for  presence of the value first - value may be not defined.
    $hasPropery = get-item -path ('{0}\{1}' -f $hive,$path)| select-object -expandproperty 'property' | where-object {$_ -eq  $name }
    if ($hasPropery -ne $null )
      $value = get-itemproperty -path ('{0}\{1}' -f $hive,$path) -name $name -ErrorAction 'SilentlyContinue' | select-object -expandproperty $name
      if ($value -eq 2) {
        write-host 'UEFI'
      } else { 
        write-host 'BIOS'
      }
    } else { 
        write-host 'BIOS'
    }

  EOF
  ) do
    its(:stdout) { should match Regexp.new('UEFI|BIOS',Regexp::IGNORECASE) }
  end
end	
