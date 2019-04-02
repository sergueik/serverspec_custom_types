require_relative '../windows_spec_helper'
context 'Certificate' do
  context 'Certificate Thumbprint Check' do
    cert_path = '\CurrentUser\TrustedPublisher'
    cert_subject = 'CN=Oracle Corporation, OU=VirtualBox'
    cert_thumbprint = '7E92B66BE51B79D8CE3FF25C15C2DF6AB8C7F2F2'
    describe command(<<-EOF
      $cert_subject = '#{cert_subject}'
      $cert_path = '#{cert_path}'

      pushd cert:
      cd $cert_path
      get-childitem | where-object { $_.Subject -match $cert_subject }| select-object -property Thumbprint,Subject | format-list
    EOF
    ) do
      its(:stdout) { should match /#{cert_thumbprint}/i}
      its(:exit_status) { should eq 0 }
    end
  end
  context 'List installed Certificates' do
    describe command(<<-EOF
      $debug = $false 
      # based on: http://www.cyberforum.ru/powershell/thread2428982.html
      $report = @()
      $remote = $false
      if ($remote) {
        $computer = $ADComputer.Name
        $user = (Get-WmiObject -Class Win32_ComputerSystem -comp $computer -ErrorAction Stop).UserName.Split('\\')[1]
        # remote
        $certPath = "\\\\${computer}\\c$\\Users\\${user}\\AppData\\Roaming\\Microsoft\\SystemCertificates\\My\\Certificates"
      } else {
        $user = $env:username
        $certPath = "c:\\Users\\${user}\\AppData\\Roaming\\Microsoft\\SystemCertificates\\My\\Certificates"
      }

      foreach ($certFile in Get-ChildItem -Path $certPath -File) {
          $certObj = certutil.exe $certFile.FullName
          if ($debug) {
            write-debug $certObj.getType() # Object[], System.Array
            write-debug $certObj
          }
          $obj = @{}
          [PSCustomObject][ordered]@{
            Name     = $certFile.Name;
            Computer = $computer;
            User     = $user;
            # NOTE: sensitive to locale
            NotAfter = ($certObj | select-string -pattern 'NotAfter: (.+)').Matches.Groups[1].Value;
            SN       = ($certObj | select-string -pattern 'Serial Number: (.+)').Matches.Groups[1].Value;
            # Note: the following variation would not work: all certutil.exe output
            # will be implicitly concatenated into a single line
            # SN       = (select-string -inputobject $certObj -pattern 'Serial Number: (.+)').Matches.Groups[1].Value;
            Provider = ($certObj | select-string -pattern 'Issuer: (.+)').Matches.Groups[1].Value;
            Subject  = ($certObj | select-string -pattern 'Subject: (.+)').Matches.Groups[1].Value;
          } | tee-object -variable obj

          $report += $obj
      }
      write-output (format-list -inputobject $report)
    EOF
    ) do
      its(:stdout) { should match /xxxx/i}
      its(:exit_status) { should eq 0 }
    end
  end
end