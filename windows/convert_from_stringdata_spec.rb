require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine
require_relative '../type/command'
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_data_sections?view=powershell-7
# https://docs.microsoft.com/en-us/previous-versions/dd347681(v=technet.10)
context 'convert from stringdata example' do
  # TODO: exercise baskslash escapes
  describe command(<<-EOF
    $o = convertfrom-stringdata -stringdata @"
    key one = value one
    key two = value two
"@
    convertto-json -inputobject $o
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout_as_json) { should include('key one') }
    its(:stdout_as_json) { should include('key one' => include('value one')) }
  end
  describe command(<<-EOF
    $o = convertfrom-stringdata -stringdata @"
    key one = value one
    key two = value two
"@
# NOTE: white space is not allowed before the string terminator
    write-output $o.'key one'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'value one' }
  end
  describe command(<<-EOF
  $o = DATA {
    convertfrom-stringdata @'
    key = some $value
'@
}
    write-output $o.Values | format-list
    # no parenthesis
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /some \$value/ }
    its(:stdout) { should match /some \$value\n?/ }
  end
end
