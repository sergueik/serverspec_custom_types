#Copyright (c) 2019 Serguei Kouzmine
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.


# dealing with 'Application Registration'
# https://docs.microsoft.com/en-us/windows/desktop/shell/app-registration

param(
  [switch]$debug
)
if ([bool]$PSBoundParameters['debug'].IsPresent) {
  $DebugPreference = 'Continue'
}
# NOTE: process management needed to run elevated
# based on: http://www.cyberforum.ru/powershell/thread1719005.html
# see also e.g. https://github.com/rgl/customize-windows-vagrant
if (-not (New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
  exit 0
}
# based on: https://www.gamedev.net/forums/topic/310631-shellexecuteex-api-call-in-c/
# https://csharp.hotexamples.com/examples/-/ShellExecuteInfo/-/php-shellexecuteinfo-class-examples.html
<# 
add-type @'
using System;
using System.Windows.Forms;
using System.Drawing;
using System.Text;
using System.Net;

using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Nt
{
	public class ProcessHelper
	{

		private static Boolean success;
		
		[StructLayout(LayoutKind.Sequential)]
		public class ShellExecuteInfo
		{
			public int cbSize = 60;
			public int fMask = 0;
			public int hwnd = 0;
			public string lpVerb = null;
			public string lpFile = null;
			public string lpParameters = null;
			public string lpDirectory = null;
			public int nShow = 0;
			public int hInstApp = 0;
			public int lpIDList = 0;
			public string lpClass = null;
			public int hkeyClass = 0;
			public int dwHotKey = 0;
			public int hIcon = 0;
			public int hProcess = 0;
		}
		[DllImport("Shell32.dll")]
		public static extern int ShellExecuteEx(ShellExecuteInfo lpExecInfo);

		public static int ShowDialog(Icon windowIcon, string file)
		{
			ShellExecuteInfo sei = new ShellExecuteInfo();
			sei.cbSize = Marshal.SizeOf(sei);
			sei.Verb = VERB_OPENAS;
			sei.Icon = windowIcon.Handle;
			sei.Mask = SEE_MASK_NOCLOSEPROCESS;
			sei.File = file;
			sei.Show = SW_NORMAL;
			int result = ShellExecuteEx(ref sei);
			if (result == 1) {
				success = true;
			} else {
				success = false;
			}
			return relr;
		}
		private void OpenFile(string filepath)
		{
			if (File.Exists(filepath)) {
				try {
					System.Diagnostics.Process.Start(filepath);
				} catch (Win32Exception ex) {
					if (ex.NativeErrorCode == 1155) {	// 1155 = ERROR_NO_ASSOCIATION
						const int SEE_MASK_NOCLOSEPROCESS = 64 , // 0x00000040
						SW_SHOWNORMAL= 1;

						var sei = new ShellExecuteInfo();
						sei.cbSize = 60;			// sizeof(ShellExecuteInfo);
						sei.fMask = SEE_MASK_NOCLOSEPROCESS;
						sei.lpVerb = "openas";
						sei.lpFile = filepath;
						sei.nShow = SW_SHOWNORMAL;			// 1 = SW_SHOWNORMAL

						int result = ShellExecuteEx(sei);
						if (result == 1)
							success = true;
					}
				}
			} else {
				throw new Win32Exception();	
				// MessageBox.Show("File \"" + filepath + "\" not found!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
			}
		}
	}
}
'@  -ReferencedAssemblies 'System.Windows.Forms.dll','System.Drawing.dll','System.Net.dll','System.Runtime.InteropServices.dll'

#>


# one of MS-recommended locations for "Finding an Application Executable" by ShellExecuteEx 
# https://docs.microsoft.com/en-us/windows/desktop/api/Shellapi/nf-shellapi-shellexecuteexa
# https://www.pinvoke.net/default.aspx/shell32/shellexecuteex.html
$appRegPath =  '/SOFTWARE/Microsoft/Windows/CurrentVersion/App Paths'

$data = @{}
pushd HKLM:
cd $appRegPath
$apps = get-childitem . | select-object -property name;
$apps| foreach-object {

  $app = $_

  pushd $appRegPath
  $path = (($app.'name') -replace 'HKEY_LOCAL_MACHINE' , '') -replace '^.*(?:\\|/)', ''
  # write-debug  "Get-ItemProperty -path ${path} -name '(default)'"
  try {
    $appPath = Get-ItemProperty -path $path -name '(default)' -errorAction stop
  } catch [Exception] {
    write-error (($_.Exception.Message) -split "`n")[0]
    # Get-ItemProperty : Property (default) does not exist at path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmmgr32.exe.
  }
  if ($appPath -ne $null) {
    $data.add(($path -replace '\..*$', '' ), $appPath.'(default)')
  }
  popd
}
popd

if ($DebugPreference -eq 'Continue') {
  format-list -InputObject $data
}
$data.keys | foreach-object {
  $app = $_
  $path = $data[$app]
  # NOTE: starting processes is unreliable due to UAC
  start-process  cmd.exe -argumentlist @('/c', 'start' , $app )
  start-sleep -seconds 5
  $result = get-process | where-object { $_.ProcessName -match $app } | select-object -Property id,path
  if ($result -ne $null) {
    # write-debug : Cannot bind argument to parameter 'Message' because it is null.
    if ($DebugPreference -eq 'Continue') {
      format-list -InputObject $result#Copyright (c) 2019 Serguei Kouzmine
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.


# dealing with 'Application Registration'
# https://docs.microsoft.com/en-us/windows/desktop/shell/app-registration

param(
  [switch]$debug
)
if ([bool]$PSBoundParameters['debug'].IsPresent) {
  $DebugPreference = 'Continue'
}
# NOTE: process management needed to run elevated
# based on: http://www.cyberforum.ru/powershell/thread1719005.html
# see also e.g. https://github.com/rgl/customize-windows-vagrant
if (-not (New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
  exit 0
}
# based on: https://www.gamedev.net/forums/topic/310631-shellexecuteex-api-call-in-c/
# https://csharp.hotexamples.com/examples/-/ShellExecuteInfo/-/php-shellexecuteinfo-class-examples.html
add-type @'
using System;
using System.Windows.Forms;
using System.Text;
using System.Net;

using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Nt
{
	public class ProcessHelper
	{

		private Boolean success;
		
		[StructLayout(LayoutKind.Sequential)]
		public class ShellExecuteInfo
		{
			public int cbSize = 60;
			public int fMask = 0;
			public int hwnd = 0;
			public string lpVerb = null;
			public string lpFile = null;
			public string lpParameters = null;
			public string lpDirectory = null;
			public int nShow = 0;
			public int hInstApp = 0;
			public int lpIDList = 0;
			public string lpClass = null;
			public int hkeyClass = 0;
			public int dwHotKey = 0;
			public int hIcon = 0;
			public int hProcess = 0;
		}
		[DllImport("Shell32.dll")]
		public static extern int ShellExecuteEx(ShellExecuteInfo lpExecInfo);

		protected override void WndProc(ref Message m)
		{
			base.WndProc(ref m);
		}

		public static int ShowDialog(Icon windowIcon, string file)
		{
			ShellExecuteInfo sei = new ShellExecuteInfo();
			sei.Size = Marshal.SizeOf(sei);
			sei.Verb = VERB_OPENAS;
			sei.Icon = windowIcon.Handle;
			sei.Mask = SEE_MASK_NOCLOSEPROCESS;
			sei.File = file;
			sei.Show = SW_NORMAL;
			int result = ShellExecuteEx(ref sei);
			if (result == 1) {
				success = true;
			} else {
				success = false;
			}
			return relr;
		}
		private void OpenFile(string filepath)
		{
/*
			if (File.Exists(filepath)) {
				try {
					System.Diagnostics.Process.Start(filepath);
				} catch (Win32Exception ex) {

					if (ex.NativeErrorCode == 1155) {	// 1155 = ERROR_NO_ASSOCIATION
*/
						const int SEE_MASK_NOCLOSEPROCESS = 64 , // 0x00000040
						SW_SHOWNORMAL= 1;

						var sei = new ShellExecuteInfo();
						sei.cbSize = 60;			// sizeof(ShellExecuteInfo);
						sei.fMask = SEE_MASK_NOCLOSEPROCESS;
						sei.lpVerb = "openas";
						sei.lpFile = filepath;
						sei.nShow = SW_SHOWNORMAL;			// 1 = SW_SHOWNORMAL

						int result = ShellExecuteEx(sei);
						if (result == 1)
							success = true;
					}
				}
			} else {
				throw new Win32Exception();	
				// MessageBox.Show("File \"" + filepath + "\" not found!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
/*
			}

		}
*/
	}
}
'@  -ReferencedAssemblies 'System.Windows.Forms.dll','System.Net.dll','System.Runtime.InteropServices.dll'


# one of MS-recommended locations for "Finding an Application Executable" by ShellExecuteEx 
# https://docs.microsoft.com/en-us/windows/desktop/api/Shellapi/nf-shellapi-shellexecuteexa
# https://www.pinvoke.net/default.aspx/shell32/shellexecuteex.html
$appRegPath =  '/SOFTWARE/Microsoft/Windows/CurrentVersion/App Paths'

$data = @{}
pushd HKLM:
cd $appRegPath
$apps = get-childitem . | select-object -property name;
$apps| foreach-object {

  $app = $_

  pushd $appRegPath
  $path = (($app.'name') -replace 'HKEY_LOCAL_MACHINE' , '') -replace '^.*(?:\\|/)', ''
  # write-debug  "Get-ItemProperty -path ${path} -name '(default)'"
  try {
    $appPath = Get-ItemProperty -path $path -name '(default)' -errorAction stop
  } catch [Exception] {
    write-error (($_.Exception.Message) -split "`n")[0]
    # Get-ItemProperty : Property (default) does not exist at path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmmgr32.exe.
  }
  if ($appPath -ne $null) {
    $data.add(($path -replace '\..*$', '' ), $appPath.'(default)')
  }
  popd
}
popd

if ($DebugPreference -eq 'Continue') {
  format-list -InputObject $data
}
$data.keys | foreach-object {
  $app = $_
  $path = $data[$app]
  # NOTE: starting processes is unreliable due to UAC
  start-process  cmd.exe -argumentlist @('/c', 'start' , $app )
  start-sleep -seconds 5
  $result = get-process | where-object { $_.ProcessName -match $app } | select-object -Property id,path
  if ($result -ne $null) {
    # write-debug : Cannot bind argument to parameter 'Message' because it is null.
    if ($DebugPreference -eq 'Continue') {
      format-list -InputObject $result
    }
    $id = $result.'id'
    # TODO: assertion
    if ($id -ne $null) {
      try {
        # write-debug ('Trying to terminate {0}' -f  $id)
        stop-process -id $id -force -erroraction stop
      } catch [Exception] {
        write-error (($_.Exception.Message) -split "`n")[0]
        # DEBUG: Cannot stop process "Defraggler (2004)" because of the following error: Access is denied
      }
    } else {
      write-error ('Failed to find process named {0}' -f $name)
    }
  }
}
    }
    $id = $result.'id'
    # TODO: assertion
    if ($id -ne $null) {
      try {
        # write-debug ('Trying to terminate {0}' -f  $id)
        stop-process -id $id -force -erroraction stop
      } catch [Exception] {
        write-error (($_.Exception.Message) -split "`n")[0]
        # DEBUG: Cannot stop process "Defraggler (2004)" because of the following error: Access is denied
      }
    } else {
      write-error ('Failed to find process named {0}' -f $name)
    }
  }
}