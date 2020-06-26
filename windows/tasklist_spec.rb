require_relative '../windows_spec_helper'

context 'ps style commands' do

  # origin:
  # https://www.cyberforum.ru/powershell/thread2671739.html
  describe command(<<-EOF
    $results = @()
    $data = tasklist.exe /fi "username eq $env:UserName" /fo:csv | convertfrom-csv
    $results = $data.'Image Name'
    $results
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    # list of processes typical for interactive user log on session Windows Desktop 
    # spec run in powershell console window
    %w/
      explorer.exe
      conhost.exe
      powershell.exe
      uru_rt.exe
      ruby.exe
    /.each do |image_name|
      its(:stdout) { should contain image_name }
    end  
  end
end
