require 'spec_helper'

context 'Using Lambda Ruby syntax to compose serverspec' do
  # squiggly heredoc removes extra indentation
  # https://www.rubyguides.com/2018/11/ruby-heredoc/
  script = <<~EOF
    ps ax -opid -oppid -ocomm -oargs 
  EOF
  run_script = lambda { |script|
    script.gsub!(/\n/, '')
    $stderr.puts ('running:' + script)
    output = %x|#{script}|
    # NOTE: %x does not return process status
    status = true
    $stderr.puts ('status: ' + status.to_s)
    $stderr.puts ('output: ' + output)
    [ status, output]
  }
  context 'test' do
    $stderr.puts "Running #{script}"
    status, comamnd_output = run_script[script]
    it { status.should be_truthy }
  end
end
