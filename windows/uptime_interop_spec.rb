require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Uptime' do

  # https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount
  # https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimeasfiletime
  # NOTE: GetTickCount returns 32 bit value, while the value stored at 0x7FFE0008 is 64 bit
  # see also: https://www.cyberforum.ru/powershell/thread3129071.html#post17038102
  context 'p/invoke' do
    describe command(<<-EOF
      Add-Type @'
        using System;
        using System.Runtime.InteropServices;

        public class UptimeHelper {
          [DllImport("kernel32.dll")]
          static extern uint GetTickCount();
          private long tickCount = GetTickCount();
          public Int64 TickCount { get { return tickCount; }}
        }
'@ -ReferencedAssemblies 'System.Runtime.InteropServices.dll'

      $o = new-object UptimeHelper
      $tickCount = $o.TickCount/1000
      $d = [System.DateTime]::Now.AddSeconds(-1 * $tickCount)
      write-output ( Get-Date $d -format 'yyyy-MM-dd hh:mm:ss')
      $s = new-timespan -seconds $tickCount
      write-output ($s.ToString('dd\\.hh\\:mm\\:ss')) 
    EOF
    ) do
      its(:stdout) { should match /\d{2}\.\d{2}:\d{2}:\d{2}/io }

    end
  end
end
