require_relative '../windows_spec_helper'

# based on: https://toster.ru/q/676382
context 'Shortcuts' do
  link_name = 'some powershell command'
  kinds =
  {
    'background' => [
      '-NoLogo',
      '-NonInteractive',
      '-NoProfile',
      '-WindowStyle Hidden',
      '-ExecutionPolicy Bypass'
    ],
    'visible' => [
      '-NoExit',
      '-ExecutionPolicy Bypass'
    ],
  }
  # Despite API name the CreateShortcut method is not meant to create the lnk file
  # but rather deserialzies the shortcut file as an object.
  describe command(<<-EOF
  
    $link_fullpath = "$HOME\\Desktop\\#{link_name}.lnk"
    $obj_shell = New-Object -ComObject WScript.Shell
    $obj_link = $obj_shell.CreateShortcut($link_fullpath.FullName)
    write-output $obj_link.arguments
  EOF
  ) do
    kinds.each do |kind,args|
      args.each do |arg|
        its(:stdout) { should match Regexp.new($arg,Regexp::IGNORECASE) }
      end
    end
  end
  context 'launching in cmd' do
    link_name = 'powershell.exe command example'
    # NOTE: have to triple the quotes around the first argument
    # double quotes lead to "Specified COMMAND search directory bad" error
    describe command(<<-EOF    
      $link_fullpath = "${env:USERPROFILE}\\Desktop\\#{link_name}.lnk"
        cmd %%- /c start """""" "${link_fullpath}"
      EOF
    ) do
      its(:exit_status) { should eq 0 }
      # will not get the output
      its(:stdout) { should be_empty }
    end
  end
end
