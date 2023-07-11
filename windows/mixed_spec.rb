require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Commands' do
  context 'medium complex' do
    describe command(<<-END_COMMAND
  write-output 'main command testing the status of pre_command success';
exit 0;
END_COMMAND
) do
      let (:pre_command) do
        #NOTE: cannot make assignments inside [ScriptBlock]::Create
        # overall looks ugly and brittle
        pre_command =  <<-END
( Invoke-Command -ScriptBlock ([Scriptblock]::Create("write-host 'pre-command'; write-host 'return true'; $return $true"))) -eq $true
END
        pre_command.gsub!(/\r?\n/,' ')
      end
      its(:stdout) { should match /pre-command/ }
      its(:stdout) { should match /success/ }
      its(:stderr) { should match /success/ }
      its(:exit_status) { should eq 0 }
    end
  end
end

# TODO :VBA
context 'Junctions ans Reparse Points' do

  describe command( <<-EOF
# Confirm that a given path is a Windows NT symlink
function Test-SymLink([string]$test_path) {
  $file_object = Get-Item $test_path -Force -ErrorAction Continue
  return [bool]($file_object.Attributes -band [IO.FileAttributes]::Archive ) `
               -and  `
         [bool]($file_object.Attributes -band [IO.FileAttributes]::ReparsePoint )
}

# Confirm that a given path is a Windows NT directory junction
function Test-DirectoryJunction([string]$test_path) {
  $file_object = Get-Item $test_path -Force -ErrorAction Continue
  return [bool]($file_object.Attributes -band [IO.FileAttributes]::Directory ) `
               -and  `
         [bool]($file_object.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

# what is the API to read directory junction target ?
function Get-DirectoryJunctionTarget([string]$test_path) {

  $command = ('cmd /c dir /L /-C "{0}"' -f
              [System.IO.Directory]::GetParent($test_path ))
  $capturing_match_expression = ( '<(?:JUNCTION|SYMLINKD|SYMLINK)>\\s+{0}\\s+\\[(?<TARGET>.+)\\]' -f
                                  [System.IO.Path]::GetFileName($test_path ))
  $result = $null
  (invoke-expression -command $command ) |
            where-object { $_ -match $capturing_match_expression } |
              select-object -first 1 |
                forEach-object {
                  $result =  $matches['TARGET']
                }
  return $result

}

# What is the API to read symlink target ?
function Get-SymlinkTarget([string]$test_path) {

  $command = ('cmd /c dir /L /-C "{0}"' -f [System.IO.Directory]::GetParent($test_path ))
  $capturing_match_expression = ( '<SYMLINK>\\s+{0}\\s+\\[(?<TARGET>.+)\\]' -f
                                  [System.IO.Path]::GetFileName($test_path ))
  $result = $null
  (invoke-expression -command $command ) |
    where { $_ -match $capturing_match_expression } |
      select-object -first 1 |
        forEach-object {
          $result =  $matches['TARGET']
        }
  return $result

}


$is_junction = Test-DirectoryJunction -test_path 'c:\\temp\\test'
write-output ('is junction: {0}' -f $is_junction )

$junction_target = Get-DirectoryJunctionTarget  -test_path 'c:\\temp\\test'
write-output ('junction target: {0}' -f $junction_target )

$is_symlink = Test-Symlink -test_path 'c:\\temp\\specinfra'
write-output ('is symlink: {0}' -f $is_symlink )

$symlink_target = Get-SymlinkTarget  -test_path 'c:\\temp\\specinfra'
write-output ('symlink target: {0}' -f $symlink_target )

EOF
) do
    its(:exit_status) {should eq 0 }
    its(:stdout) { should match /is symlink: True/  }
    its(:stdout) { should match /symlink target: specinfra-2.43.5.gem/i   }
    its(:stdout) { should match /is junction: True/  }
    its(:stdout) { should match /junction target: c:\\windows\\softwareDistribution/i   }
  end

end


context 'Writing Files' do
  describe command 'Add-Content -Path "C:\\temp\\a.txt" -Value @(1,2,3)' do
    its(:exit_status) {should eq 0 }
  end
  describe command 'write-output "123" | out-file -filepath "c:\\temp\\a.txt" -append' do
    its(:exit_status) {should eq 0 }
  end
end

context 'Command Output' do
  # Pre-command does not work - invalid Powershell sytnax in generated command
  # let(:pre_command) { 'write-output "123" | out-file -filepath "c:\\temp\\a.txt" -append' }
  # let(:pre_command) { '(Add-Content -Path "C:\\temp\\a.txt" -Value @(4,5,6))'  }

  describe file( "c:\\temP\\a.txt") do

    it { should be_file  }
    it { should contain(/1|2|3/)  }
  end
end


context 'Junctions ans Reparse Points with pinvoke' do
  # requires custom specinfra
  context 'Junctions ans Reparse Points' do
    describe file('c:/temp/xxx') do
     it { should be_symlink }
    end
  end
  describe command( <<-EOF

# use pinvoke to read directory junction /  symlink target
#  http://chrisbensen.blogspot.com/2010/06/getfinalpathnamebyhandle.html
Add-Type -TypeDefinition @"
// "

using System;
using System.Collections.Generic;
using System.ComponentModel; // for Win32Exception
using System.Data;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public class Utility
{

    private const int FILE_SHARE_READ = 1;
    private const int FILE_SHARE_WRITE = 2;

    private const int CREATION_DISPOSITION_OPEN_EXISTING = 3;

    private const int FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

    // http://msdn.microsoft.com/en-us/library/aa364962%28VS.85%29.aspx
    // http://pinvoke.net/default.aspx/kernel32/GetFileInformationByHandleEx.html

    // http://www.pinvoke.net/default.aspx/shell32/GetFinalPathNameByHandle.html
    [DllImport("kernel32.dll", EntryPoint = "GetFinalPathNameByHandleW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int GetFinalPathNameByHandle(IntPtr handle, [In, Out] StringBuilder path, int bufLen, int flags);

    // https://msdn.microsoft.com/en-us/library/aa364953%28VS.85%29.aspx


    // http://msdn.microsoft.com/en-us/library/aa363858(VS.85).aspx
    // http://www.pinvoke.net/default.aspx/kernel32.createfile
    [DllImport("kernel32.dll", EntryPoint = "CreateFileW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern SafeFileHandle CreateFile(string lpFileName, int dwDesiredAccess, int dwShareMode,
    IntPtr SecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);

    public static string GetSymbolicLinkTarget(DirectoryInfo symlink)
    {
        SafeFileHandle directoryHandle = CreateFile(symlink.FullName, 0, 2, System.IntPtr.Zero, CREATION_DISPOSITION_OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, System.IntPtr.Zero);
        if (directoryHandle.IsInvalid)
            throw new Win32Exception(Marshal.GetLastWin32Error());

        StringBuilder path = new StringBuilder(512);
        int size = GetFinalPathNameByHandle(directoryHandle.DangerousGetHandle(), path, path.Capacity, 0);
        if (size < 0)
            throw new Win32Exception(Marshal.GetLastWin32Error());
        // http://msdn.microsoft.com/en-us/library/aa365247(v=VS.85).aspx
        if (path[0] == '\\\\' && path[1] == '\\\\' && path[2] == '?' && path[3] == '\\\\')
            return path.ToString().Substring(4);
        else
            return path.ToString();
    }

}
"@ -ReferencedAssemblies 'System.Windows.Forms.dll','System.Runtime.InteropServices.dll','System.Net.dll','System.Data.dll','mscorlib.dll'

$symlink_directory = 'c:\\temp\\test'
$symlink_directory_directoryinfo_object = New-Object System.IO.DirectoryInfo ($symlink_directory)
$junction_target = [utility]::GetSymbolicLinkTarget($symlink_directory_directoryinfo_object)
write-output ('junction target: {0}' -f $junction_target )

EOF
) do
    its(:exit_status) {should eq 0 }
    its(:stdout) { should match /junction target: c:\\windows\\softwareDistribution/i }
  end


  describe command( <<-EOF

# use pinvoke to read directory junction /  symlink target
#  http://chrisbensen.blogspot.com/2010/06/getfinalpathnamebyhandle.html
Add-Type -TypeDefinition @"
// "

using System;
using System.Collections.Generic;
using System.ComponentModel; // for Win32Exception
using System.Data;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public class Utility
{

    private const int FILE_SHARE_READ = 1;
    private const int FILE_SHARE_WRITE = 2;

    private const int CREATION_DISPOSITION_OPEN_EXISTING = 3;

    private const int FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

    // http://msdn.microsoft.com/en-us/library/aa364962%28VS.85%29.aspx
    // http://pinvoke.net/default.aspx/kernel32/GetFileInformationByHandleEx.html

    // http://www.pinvoke.net/default.aspx/shell32/GetFinalPathNameByHandle.html
    [DllImport("kernel32.dll", EntryPoint = "GetFinalPathNameByHandleW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int GetFinalPathNameByHandle(IntPtr handle, [In, Out] StringBuilder path, int bufLen, int flags);

    // https://msdn.microsoft.com/en-us/library/aa364953%28VS.85%29.aspx


    // http://msdn.microsoft.com/en-us/library/aa363858(VS.85).aspx
    // http://www.pinvoke.net/default.aspx/kernel32.createfile
    [DllImport("kernel32.dll", EntryPoint = "CreateFileW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern SafeFileHandle CreateFile(string lpFileName, int dwDesiredAccess, int dwShareMode,
    IntPtr SecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, IntPtr hTemplateFile);

    public static string GetSymbolicLinkTarget(FileInfo symlink)
    {
        SafeFileHandle fileHandle = CreateFile(symlink.FullName, 0, 2, System.IntPtr.Zero, CREATION_DISPOSITION_OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, System.IntPtr.Zero);
        if (fileHandle.IsInvalid)
            throw new Win32Exception(Marshal.GetLastWin32Error());

        StringBuilder path = new StringBuilder(512);
        int size = GetFinalPathNameByHandle(fileHandle.DangerousGetHandle(), path, path.Capacity, 0);
        if (size < 0)
            throw new Win32Exception(Marshal.GetLastWin32Error());
        // http://msdn.microsoft.com/en-us/library/aa365247(v=VS.85).aspx
        if (path[0] == '\\\\' && path[1] == '\\\\' && path[2] == '?' && path[3] == '\\\\')
            return path.ToString().Substring(4);
        else
            return path.ToString();
    }


}
"@ -ReferencedAssemblies 'System.Windows.Forms.dll','System.Runtime.InteropServices.dll','System.Net.dll','System.Data.dll','mscorlib.dll'


$symlink_file = 'c:\\temp\\specinfra'

$symlink_file_fileinfo_object = New-Object System.IO.FileInfo ($symlink_file)
$symlink_target = [utility]::GetSymbolicLinkTarget($symlink_file_fileinfo_object)
write-output ('symlink target: {0}' -f $symlink_target )


EOF
) do
    its(:exit_status) {should eq 0 }
    its(:stdout) { should match /symlink target: C:\\temp\\specinfra-2.43.5.gem/i }
  end


end

context 'Inspecting registry key created by the installer' do
  describe command ( <<-EOF
$version = '2.6.4'
$nunit_registry_key = "HKCU:\\Software\\nunit.org\\NUnit\\${version}"
if (-not (Get-ChildItem $nunit_registry_key -ErrorAction 'SilentlyContinue')){
  throw 'Nunit is not installed.'
}
$item = (Get-ItemProperty -Path $nunit_registry_key ).InstallDir
$nunit_install_dir = [System.IO.Path]::GetDirectoryName($item)

$assembly_list = @{
  'nunit.core.dll' = 'bin\\lib';
  'nunit.framework.dll' = 'bin\\framework';
}

pushd $nunit_install_dir
foreach ($assembly in $assembly_list.Keys)
{
  $assembly_path = $assembly_list[$assembly]
  pushd ${assembly_path}
  write-debug ('Loading {0} from {1}' -f $assembly,$assembly_path )
  if (-not (Test-Path -Path $assembly)) {
    throw ('Assembly "{0}" not found in "{1}"' -f $assembly, $assembly_path )
  }
  Add-Type -Path $assembly
  popd
}

[NUnit.Framework.Assert]::IsTrue($true)

EOF
) do
    its(:exit_status) {should eq 0 }
    its(:stderr) { should be_empty }
  end
end

context 'Default Site' do
  describe windows_feature('IIS-Webserver') do
    it{ should be_installed.by('dism') }
  end
  describe iis_app_pool('DefaultAppPool') do
    it{ should exist }
  end
  describe file('c:/inetpub/wwwroot') do
    it { should be_directory }
  end
end
context 'World Wide Web Publishing Service' do
  describe service('W3SVC') do
    # comment slow command
    it { should be_running }
    it { should have_property('StartName') }
    # it { should have_property('StartName','LocalSystem') }

  end
end
context 'Windows Process Activation Service' do
  describe service('WAS') do
    # comment slow command
    it { should be_running }
  end

end
context 'chained commands' do
  context 'basic' do
    before(:each) do
      # interpolation
      # Specinfra::Runner::run_command("echo \"it works\" > #{@logfile}")
      Specinfra::Runner::run_command("echo \"it works\" > c:\\temp\\a.txt")
    end
    @logfile = 'c:\temp\a.txt'
    describe command("(get-content -path '#{@logfile}')") do
      its(:stdout) { should match /it works/ }
      its(:exit_status) { should eq 0 }
    end
  end
  context 'moderate' do
    context 'download .net assembly for execution' do
      @url =  'http://github.com/nunit/nunitv2/releases/download/2.6.4/NUnit-2.6.4.zip'
      @download_path =  'c:/temp'
      @file =  'nunit.zip'
      before(:each) do
       Specinfra::Runner::run_command(<<-END_COMMAND1
\$o = new-object -typename 'System.Net.WebClient'
\$o.DownloadFile('#{@url}','#{@download_path}/#{@file}')
END_COMMAND1
)
      end
      describe command(<<-END_COMMAND

write-output 'Check the file is present'
\$zip_path = '#{@download_path}/#{@file}'
test-path -LiteralPath \$zip_path -ErrorAction Stop
write-output 'extract the file'
[string]\$extract_path = ('{0}\\Desktop\\Extract' -f \$env:USERPROFILE)
[System.IO.Directory]::CreateDirectory(\$extract_path)
add-type  -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::ExtractToDirectory(\$zip_path, \$extract_path)
\$dll_name = 'nunit.framework.dll'
write-output 'load assembly'
add-type -path ('{0}\\Desktop\\Extract\\NUnit-2.6.4\\bin\\{1}' -f \$env:USERPROFILE , \$dll_name)
write-output 'throw assertion exception'
[NUnit.Framework.Assert]::IsTrue(\$true -eq \$false)
write-output 'complete execution'
return \$true
END_COMMAND
) do
      its(:stdout) { should match /extract the file/ }
      its(:stdout) { should match /load assembly/ }
      its(:stdout) { should match /throw assertion exception/ }
      its(:stdout) { should match /complete execution/ }
      its(:stderr) { should match /Exception/ }
      its(:stderr) { should match /Expected: True/ }
      its(:stderr) { should match /But was:  False/ }
      # its(:exit_status) { should == 1 }
      end
    end
  end
end
