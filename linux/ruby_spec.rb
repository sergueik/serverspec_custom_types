require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Run Ruby' do

  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '/tmp'
    ruby  --version
    1>/dev/null 2>/dev/null popd
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty }
    its(:stdout) { should contain Regexp.new 'ruby 2.[0-5].\dp\d+' }
  end

  # based on: https://github.com/rejasupotaro/android-dev-env-serverspec/blob/master/spec/localhost/android-dev-env_spec.rb
  describe 'Custom methods' do
    def create_cmd(command)
      Serverspec::Type::Command.new(command)
    end
    def specific_command(command, comment)
      $stderr.puts comment
      create_cmd(<<-EOF
        1>/dev/null 2>/dev/null pushd '/tmp'
        #{command}
        1>/dev/null 2>/dev/null popd
      EOF
      )
    end
    # `specific_command` is not available on an example group (e.g. a `describe` or `context` block). It is only available from within individual examples (e.g. `it` blocks) or from constructs that run in the scope of an example (e.g. `before`, `let`, etc).
    it do
      o = specific_command('ruby --version', 'Running Ruby')
      expect o.exit_status.eql? 0
      # its` is not available from within an example (e.g. an `it` block)
      # its(:exit_status) { should eq 0 }
      # TODO: expect o.exit_status.eql?(0).to be_truthy
    end
  end
end
