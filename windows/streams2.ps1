# based on: https://www.cyberforum.ru/powershell/thread2632563.html

# see also: http://forum.oszone.net/thread-341800.html
$file_path = "${env:TEMP}\stream_test.txt"
set-content -path $file_path -value 'stream test'

$stream_name = 'Zone.Identifier'
remove-item -path $file_path -stream $stream_name -erroraction silentlycontinue
$stream_name = 'Stream.Data'
$data = 'custom data'
write-output ('writing custom data into stream {0}' -f $stream_name)
set-content -path $file_path -stream $stream_name -value ("[{0}]`n{1}" -f $stream_name, $data)
# usually formatted with the stream name and data:
#
# [ZoneTransfer]
# ZoneId=3
write-output ('List all streams in the file {0}' -f $file_path )
get-content -path $file_path -stream * -erroraction silentlycontinue
# NOTE : fail with Get-Content : Could not open the alternate data stream '*' of the file

@('Stream.Data', 'Zone.Identifier') | foreach-object {
  $stream_name = $_
  write-output ('List stream {0} in the file {1}' -f $stream_name, $file_path )
  get-item -path $file_path -stream $stream_name -erroraction silentlycontinue

  if ((get-item -path $file_path -stream * -erroraction stop | where-object {$_.Stream -eq $stream_name} ) -ne $null) {
    write-output 'get-item:'
    get-item -path $file_path -stream $stream_name -erroraction stop
    write-output 'get-content:'
    get-content -path $file_path -Stream $stream_name -erroraction stop
  }
}

remove-item -path $file_path

# see also: https://blogs.msmvps.com/bsonnino/2016/11/24/alternate-data-streams-in-c/
# (not pure: relies on 'Trinet.Core.IO.Ntfs' assembly)
# see also: https://stackoverflow.com/questions/604960/ntfs-alternate-data-streams-net
# for further discussions of the pinvoke'able "kernel32.dll" NTFS methods
add-type -typeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.IO;
public class Program {
	/// GENERIC_WRITE -> (0x40000000L)
	public const int GENERIC_WRITE = 1073741824;
	public const int FILE_SHARE_DELETE = 4;
	public const int FILE_SHARE_WRITE = 2;
	public const int FILE_SHARE_READ = 1;
	public const int OPEN_ALWAYS = 4;
	[DllImportAttribute("kernel32.dll", EntryPoint = "CreateFileW")]
	static public extern System.IntPtr CreateFileW( [InAttribute()] [MarshalAsAttribute(UnmanagedType.LPWStr)] string lpFileName, uint dwDesiredAccess,  uint dwShareMode, [InAttribute()] System.IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, [InAttribute()] System.IntPtr hTemplateFile );
	static public void Main(string[] args)	{
		var mainStream = CreateFileW( "testfile", GENERIC_WRITE, FILE_SHARE_WRITE, IntPtr.Zero, OPEN_ALWAYS, 0, IntPtr.Zero);

		var stream = CreateFileW( "testfile:stream", GENERIC_WRITE,FILE_SHARE_WRITE, IntPtr.Zero, OPEN_ALWAYS, 0, IntPtr.Zero);
	}
}
'@
