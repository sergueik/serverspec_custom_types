# origin: https://www.cyberforum.ru/powershell/thread3129071.html
# see also: http://lazplanet.blogspot.com/2013/07/how-to-get-computer-running-time.html
# https://www.sysnet.pe.kr/2/0/1744
# http://studentdeng.github.io/blog/page/17/ for 0x7FFE0014
<#
using System;
using System.Runtime.InteropServices;

class Program
{
typedef struct _KSYSTEM_TIME  
{  
     ULONG LowPart;  
     LONG High1Time;  
     LONG High2Time;  
} KSYSTEM_TIME, *PKSYSTEM_TIME;


    static void Main(string[] args)
    {
        IntPtr ptr = new IntPtr(0x7FFE0008);
        KSYSTEM_TIME systemTime = new KSYSTEM_TIME();
        Marshal.PtrToStructure(ptr, systemTime);

        Console.WriteLine("LowPart: " + systemTime.LowPart);
        Console.WriteLine("HighTime: " + systemTime.HighTime);
        Console.WriteLine("High2Time: " + systemTime.High2Time);

        ulong fullTime = (ulong)systemTime.LowPart | ((ulong)systemTime.HighTime << 32);
        Console.WriteLine("KSYSTEM_TIME: \t\t" + fullTime);
/*
LowPart:   2242934063
HighTime:  102
High2Time: 102
KSYSTEM_TIME:  441971822558
*/
#>
using namespace System.Runtime.InteropServices
 
$ksystem_time = {
  param([Byte]$Offset)
  end {
    [BitConverter]::ToInt64(
      (0..11).ForEach{
        [Marshal]::ReadByte([IntPtr](0x7FFE0000 + $Offset), $_)
      }, 0
    )
  }
}
 
[DateTime]::FromFileTime((& $ksystem_time 0x14) - (& $ksystem_time 0x08))


# https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount
# https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimeasfiletime
# https://www.tabnine.com/code/java/methods/com.sun.jna.platform.win32.Kernel32/GetTickCount
# https://www.pinvoke.net/default.aspx/kernel32.getsystemtimeasfiletime
# NOTE: probably better to conver to plain C# add-type
# https://www.tabnine.com/code/java/methods/com.sun.jna.platform.win32.Kernel32/GetTickCount
# https://github.com/java-native-access/jna/blob/master/contrib/platform/test/com/sun/jna/platform/win32/Kernel32Test.java
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class UptimeHelper {

[DllImport("kernel32.dll")]
static extern uint GetTickCount();
private long entryTick = GetTickCount();
public Int64 EntryTick { get { return entryTick; }}
	}
'@ -ReferencedAssemblies 'System.Runtime.InteropServices.dll'

$o = new-object UptimeHelper
$tickCount= $o.EntryTick/1000

[System.DateTime]::Now.AddSeconds(-1 * $u)
write-output('{0:0.#0} weeks {1:0.#0} days {2:0.#0} hours {3:0.#0} minutes' -f ($u/86400/7), ($u/86400), ($u/3600), ($u/60))
