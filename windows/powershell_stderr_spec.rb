  require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

  # based on:
  # https://stackoverflow.com/questions/4998173/how-do-i-write-to-standard-error-in-powershell
  # note the convoluted debate abot differences of that happen *Inside* PowerShell, *Outside* PowerShell,
  # and constructs like "there is no such thing as stdout and stderr, in PowerShell"
  context 'stderr capture' do
    context 'launching in powershell' do
      
      describe command(<<-EOF    
        1..3 | foreach-object {
          write-output ('output message ' + $_ )
        }
        1..3 | foreach-object {
          $error_message =  ('error message ' + $_ )
          [Console]::Error.WriteLine($error_message)
        }
        exit 0
      EOF
      ) do
        # technical implementation
        its(:exit_status) { should eq 1 }
        its(:stderr) { should match 'Preparing modules for first use' }
        
        its(:stdout) { should match 'output message 1' }
        its(:stderr) { should match 'error message 1' }
      end
    end
  end  
