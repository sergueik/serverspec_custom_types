require_relative '../windows_spec_helper'

# See also:
# https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil
# https://docs.microsoft.com/en-us/windows/win32/wes/windows-event-log-tools
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
    describe command(<<-EOF
        & wevtutil.exe qe #{logname}
      EOF
    ) do
        its(:exit_status) { should eq 0 }
    end
end
