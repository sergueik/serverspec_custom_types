require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"

# see also: https://habr.com/ru/post/467115/
# and https://habr.com/ru/post/466987/
# for fancy ls alternatives
context 'Valid symlink' do
  [
    '/usr/bin/pip-python',
    '/usr/bin/vim',
    '/usr/bin/VBoxClient',
  ].each do |filepath|
    describe file(filepath) do
      it { should be_symlink }
      # a home-brewed version of `should be_linked_to`
      # not using `dirname` to cope with broken link detection
      split_filename_from_filepath = Regexp.new('^(.+)/([^/]+)$').match(filepath)
      dir = split_filename_from_filepath[1]
      filename = split_filename_from_filepath[2]
      describe command(<<-EOF
        find #{dir} -type l -and -name '#{filename}' -exec test -e {} \\; -print
      EOF
      ) do
        its(:stdout) { should_not be_empty }
      end
      describe command(<<-EOF
        find '#{dir}' -type l -and -name '#{filename}' -xargs -IX readlink X
      EOF
      ) do
        its(:stdout) { should_not be_empty }
        its(:stderr) { should be_empty }
      end
    end
  end
end
