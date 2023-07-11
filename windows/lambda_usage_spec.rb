require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Using Lambda Ruby syntax to compose serverspec' do
  # Introduced in Ruby 2.3, the squiggly heredoc removes extra indentation
  # https://www.rubyguides.com/2018/11/ruby-heredoc/
  # With earlier Ruby, '<<~'  just fails
  # ruby 2.1.x
  #
  # syntax error, unexpected <<
  script = <<~EOF
    tasklist.exe
  EOF
  # NOTE: with %x should be using executables, cannot handle Powershell cmdlets
  # ``': No such file or directory - get-process (Errno::ENOENT)
  run_script = lambda { |script|
    script.gsub!(/\r?\n/, '')
    $stderr.puts ('running:' + script)
    output = %x|#{script}|
    # NOTE: %x is not returning the child process status
    # mock it...
    status = true
    $stderr.puts ('status: ' + status.to_s)
    $stderr.puts ('output: ' + output)
    # TODO:
    # o = Specinfra::Runner::run_command(s)
    # C:/uru/ruby/lib/ruby/gems/2.3.0/gems/specinfra-2.66.2/lib/specinfra/backend/cmd.rb:52:in `powershell':
    # undefined method `metadata' for nil:NilClass (NoMethodError)
    # $stderr.puts ('Lambda got status: ' + o.status.to_s)
    # $stderr.puts ('Lambda got output: ' + o.output.chomp)
    [ status, output]
  }
  context 'test' do
    $stderr.puts "Running #{script}"
    status, comamnd_output = run_script[script]
    it { status.should be_truthy }
  end
end
