require_relative '../windows_spec_helper'

context 'Registry Binary Value' do
  task = '{8A2CE4D0-352E-43FE-8FB1-05140580EA96}'
  key = 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Schedule/TaskCache/Tasks/' + task
  describe command(<<-EOF
    [byte[]]$rawdata = (get-item -path "#{ key.gsub('/', '\\\\').gsub('HKEY_LOCAL_MACHINE', 'HKLM:') }").getValue('actions')
    $stringdata = [System.Text.Encoding]::Unicode.GetString($rawdata)
    write-output $stringdata
  EOF
  ) do
	# NOTE: MSTASK Registry entry has custom format, one does not expect plaintext
    its(:stdout) { should match /powershell.exe/}
  end
end
