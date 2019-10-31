require_relative '../windows_spec_helper'

# based on  https://toster.ru/q/658135
# single-line cmd scripts are not popular but may exist in legacy environments

require 'fileutils'

$DEBUG = (ENV.fetch('DEBUG', 'false') =~ /^(true|t|yes|y|1)$/i)

context 'Jackson YAML', :if => os[:family] == 'windows' do
  describe command(<<-EOF
    cmd %%- /c "SETLOCAL ENABLEDELAYEDEXPANSION& >NUL set /a MYVAR=%RANDOM% & echo _!MYVAR!_"
  EOF
  ) do
    its(:stdout) { should match /_\d+_/ }
    its(:stdout) { should_not match /_!MYVAR!_/i }
  end
  describe command(<<-EOF
    cmd %%- /v /c ">NUL set /a MYVAR=%RANDOM% & echo _!MYVAR!_"
  EOF
  ) do
    its(:stdout) { should match /_\d+_/ }
    its(:stdout) { should_not match /_!MYVAR!_/i }
  end
  # TODO: set /a MYVAR=%RANDOM% & call echo _^%MYVAR^%_
end
