require_relative '../windows_spec_helper'
# http://ss64.com/ps/get-winevent.html

context 'Event Log' do
    logname = 'Microsoft-Windows-PowerShell/Operational'
    describe command(<<-EOF
        & wevtutil.exe el
      EOF
    ) do
        its(:stdout) { should match /#{logname}/io }
      end
    describe command(<<-EOF
        & wevtutil.exe gl #{logname}
      EOF
    ) do
        its(:stdout) { should match /name: #{logname}/io }
        its(:stdout) { should match /enabled: true/io }
    end
    logfilename = '%SystemRoot%/System32/Winevt/Log/Microsoft-Windows-PowerShell%4Operational.evtx'
    describe command(<<-EOF
        property = 'logFileName'

        $logname = '#{logname}'
        $data = & wevtutil.exe gl $logname |  
        convertfrom-string  | 
        where-object { $_.'P2' -match $property } | 
        select-object -expandproperty 'P3'
        $data -replace '\\\\', '/'


      EOF
    ) do
        its(:stdout) { should contain logfilename }
	# ArgumentError:  too short meta escape

    end
    describe command(<<-EOF
        & wevtutil.exe qe #{logname}
      EOF
    ) do
        its(:exit_status) { should eq 0 }
    end
end
