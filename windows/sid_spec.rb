require_relative '../windows_spec_helper'
require 'win32/security'

# based on https://windowsnotes.ru/cmd/kak-uznat-sid-polzovatelya/
# https://toster.ru/q/643139
# https://www.rubydoc.info/gems/win32-security/0.3.0/Win32/Security/SID
context 'Windows Account' do
  username = ENV.fetch('USERNAME','vagrant')
  obj_user = Win32::Security::SID.new(username)
  sid_binary = obj_user.sid.to_s
  sid_string = obj_user.to_s


  describe command(<<-EOF
    $o = get-wmiobject -Class 'win32_userAccount' -Filter "name='#{username}' and domain='${env:USERDOMAIN}'"
    write-output $o.sid
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain sid_string }
  end
  describe command(<<-EOF
    ([wmi]"win32_SID.SID='#{sid_string}'").AccountName
  EOF
  ) do
    its(:stdout) { should contain username }
    its(:exit_status) { should eq 0 }
  end
  describe command('cmd %%- /c whoami.exe /user') do
    let(:pre_command) { 'echo dummy'  }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not contain sid_binary }
    its(:stdout) { should contain sid_string }
  end

  # ([wmi]"win32_userAccount.Domain='${env:USERDOMAIN}', Name='${env:USERNAME}'").sid
  # Cannot convert value "win32_userAccount.Domain='sergueik42', Name='sergueik'" to type "System.Management.ManagementObject". Error: "Invalid parameter "

end


#  Constant SID Summary in string format
#  # support.microsoft.com/kb/243330 for details.
#  Null = 'S-1-0'
#  Nobody = 'S-1-0-0'
#  World = 'S-1-1'
#  Everyone = 'S-1-1-0'
#  Local = 'S-1-2'
#  Creator = 'S-1-3'
#  CreatorOwner = 'S-1-3-0'
#  CreatorGroup = 'S-1-3-1'
#  CreatorOwnerServer = 'S-1-3-2'
#  CreatorGroupServer = 'S-1-3-3'
#  NonUnique = 'S-1-4'
#  Nt = 'S-1-5'
#  Dialup = 'S-1-5-1'
#  Network = 'S-1-5-2'
#  Batch = 'S-1-5-3'
#  Interactive = 'S-1-5-4'
#  Service = 'S-1-5-6'
#  Anonymous = 'S-1-5-7'
#  Proxy = 'S-1-5-8'
#  EnterpriseDomainControllers = 'S-1-5-9'
#  PrincipalSelf = 'S-1-5-10'
#  AuthenticatedUsers = 'S-1-5-11'
#  RestrictedCode = 'S-1-5-12'
#  TerminalServerUsers = 'S-1-5-13'
#  LocalSystem = 'S-1-5-18'
#  NtLocal = 'S-1-5-19'
#  NtNetwork = 'S-1-5-20'
#  BuiltinAdministrators = 'S-1-5-32-544'
#  BuiltinUsers = 'S-1-5-32-545'
#  Guests = 'S-1-5-32-546'
#  PowerUsers = 'S-1-5-32-547'
#  AccountOperators = 'S-1-5-32-548'
#  ServerOperators = 'S-1-5-32-549'
#  PrintOperators = 'S-1-5-32-550'
#  BackupOperators = 'S-1-5-32-551'
#  Replicators = 'S-1-5-32-552'


# NOTE: invalid multibytechar (UTF-8) (SyntaxError)
# NOTE:
# require 'win32-security'
# cannot load such file -- win32-security (LoadError)
# still listed with
# gem list win32-security
