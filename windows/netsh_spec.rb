require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine
context 'Inspecting netsh command' do
  describe command (<<-EOF
    $o = netsh.exe interface show interface | select-string -pattern '(enabled|disabled)'|convertfrom-string
    write-output ([String]::Join(' ', @($o.P4,$o.P5,$o.P6,$o.P7)))
  EOF
  ) do
    its(:stdout) { should contain 'Local Area Connection' }
  end
  acl = 'http://+:5985/wsman/'
  describe command (<<-EOF
    $acl = '#{acl}'
    $o = netsh.exe http show urlacl $acl | select-string -pattern 'SDDL'|convertfrom-string
    start-sleep -millisecond 100
    $o = netsh.exe http show urlacl $acl | select-string -pattern 'SDDL'|convertfrom-string
    $result = $o.P3
    write-output $result
  EOF
  ) do
    its(:stdout) { should match Regexp.new(Regexp.escape('D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)')) }
  end
  # TODO: demonstrate User expectations
end

# origin: https://blogs.msdn.microsoft.com/oldnewthing/20180703-00/?p=99145
# NOTE: this test is currenlty a mock up

