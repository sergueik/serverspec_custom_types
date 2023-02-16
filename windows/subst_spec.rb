require_relative '../windows_spec_helper'
$DEBUG = (ENV.fetch('DEBUG', 'false') =~ /^(true|t|yes|y|1)$/i)

# see also: https://www.cyberforum.ru/powershell/thread3080116.html

context 'Windows DOS Disks', :if => os[:family] == 'windows' do
  drive = 'T:'
  describe command(<<-EOF
    & C:\\Windows\\System32\\subst.exe #{drive} /d |out-null
    & C:\\Windows\\System32\\subst.exe #{drive} $env:TEMP
    [IO.DriveInfo]::GetDrives() | foreach-object { write-output $_.Name }
    & C:\\Windows\\System32\\subst.exe #{drive} /d
  EOF
  ) do
    # its(:exit_status) { should eq 0 }
    its(:stdout) { should match( /#{drive}\\/i ) }
    # Drive already SUBSTed
    # Invalid parameter - T:
    # out-file : FileStream was asked to open a device that was not a file.
    # For support for devices like 'com1:' or 'lpt1:', 
    # call CreateFile, then use the FileStream constructors 
    # that take an OS handle as an Int
    # C:\\Windows\\System32\\subst.exe #{drive} /d 2>NUL 
  end
end

context 'Windows DOS Disks (2)' do
  drive = 'T:'
    before(:each) do
      Specinfra::Runner::run_command(<<-EOF
        & C:\\Windows\\System32\\subst.exe #{drive} /d |out-null
        & C:\\Windows\\System32\\subst.exe #{drive} $env:TEMP
      EOF
      )
    end
    describe command(<<-EOF
      [IO.DriveInfo]::GetDrives() | foreach-object { write-output $_.Name }
    EOF
    ) do
    # its(:exit_status) { should eq 0 }
    its(:stdout) { should match( /#{drive}\\/i ) }
  end
end
