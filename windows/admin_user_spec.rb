require_relative '../windows_spec_helper'
context 'Admin check' do
  # origin:
  # https://www.cyberforum.ru/powershell/thread2743961.html
  # NOTE: does not work on stanalone hosts:
  # after installing the cmdlet
  # https://gallery.technet.microsoft.com/scriptcenter/Get-LocalGroupMember-d2ddad6f
  # the error is:
  # format-default : The following exception occurred while retrieving member
  # "distinguishedName": "Unknown error (0x80005000)"
  describe command(<<-EOF
    param (
      [Parameter(Mandatory = $false)]
      [string]
      $user = "$env:username"
    )
     
    $sid = 'S-1-5-32-544'
    $admins = (Get-LocalGroupMember -SID $sid).Name
     
    if ("$env:ComputerName\\$user" -in $admins){
      exit 0 
    } else { exit 1 
    }
  EOF
  ) do
    its(:exit_status) {should eq 0 }
  end
end