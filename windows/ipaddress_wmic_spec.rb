require_relative '../windows_spec_helper'

context 'IP Address' do
  # NOTE:` is the Powershell escape character, required here for parenthesis
  describe command(<<-EOF
   wmic.exe /LOCALE:MS_409 nicconfig where `(IPEnabled=TRUE AND DHCPServer IS NOT null `) get IPAddress /format:list
  EOF
  ) do
    its(:stdout) do
      should match /{"[0-9.]+"/
    end
  end
  describe command(<<-EOF
    wmic.exe /LOCALE:MS_409 path Win32_NetworkAdapterConfiguration where `(IPEnabled=TRUE AND DHCPServer IS NOT null `) get IPAddress /format:list
  EOF
  ) do
    its(:stdout) do
      should match /{"[0-9.]+"/
    end
  end
end

