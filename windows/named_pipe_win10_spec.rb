require_relative '../windows_spec_helper'

# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-powershell-named-pipes
# requies Windows 8.1 and Powershell 5.0

context 'Pipes' do
  context 'Powershell 5.x' do

    named_pipes = [
      'InitShutdown',
      'lsass',
      'ntsvcs',
      'scerpc',
      'epmapper',
      'LSM_API_service',
      'atsvc',
      'eventlog',
      'spoolss',
      'wkssvc',
      'srvsvc',
      'ROUTER'
    ]
    # NOTE: the following command turns out to be hanging too
    # get-childitem -Path "\\.\pipe\" -Filter '*Google*' | select-object -first 1 | select-object -property *
    describe command(<<-EOF
     get-childitem -Path "\\\\.\\pipe\\" |
     where-object { -not $_.PSIsContainer } |
     where-object {$_.Directory -match  '\\\\.\\\\pipe$' } |
     select-object -property Name
    EOF
    ) do
      named_pipes.each do |named_pipe|
        its (:stdout) { should contain named_pipe }
      end
      its (:stdout) { should match /PSHost\.[0-9.]+\.DefaultAppDomain.powershell/ }
    end
  end
end
