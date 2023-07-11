require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# based on https://www.cyberforum.ru/shell/thread3021773.html#post16457085
# NOTE: not matching the semantics of https://serverspec.org/resource_types.html#file
context 'File Type' do
  file = '/opt/vivaldi/vivaldi-bin'
  describe command("export F='#{file}'; find $F -user root -exec sh -c \"file '{}' | grep -q 'ELF'\" \\; -print") do
    its(:stdout) { should match Regexp.new(file)}
  end
end

