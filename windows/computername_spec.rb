require_relative '../windows_spec_helper'

context 'Windows Hostname' do
  # according to 
  # https://techcommunity.microsoft.com/t5/windows-server-for-it-pro/hostname-character-limit/m-p/1068231
  # https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou
  # there is a hard 15 byte (characters) limit on NETBIOS-compatible hostnames, also reflected in Active Directory
  # Windows does not permit computer names that exceed 15 characters, and you cannot specify a DNS host name that differs from the NETBIOS host name.
  # the $env:COMPUTERNAME will display the NETBIOS-truncated to 15 char portion

  hostname = Socket.gethostname

  describe command 'write-output ([System.Net.Dns]::GetHostName())' do
    its(:stdout) { should match hostname }
  end
  describe command 'write-output ((Get-WmiObject win32_computersystem).DNSHostName)' do
    its(:stdout) { should match hostname }
  end
end
