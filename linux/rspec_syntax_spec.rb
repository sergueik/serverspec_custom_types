require 'spec_helper'

# NOTE: the rspecvariables are not explosed 
# the following few examples print 'Skipped some test:' regardless of the value of test_xxx variable

test_false = false
context 'Rspec Syntax' do
  context 'Bad Example to skip XML test', :if => test_false do
    $stderr.puts 'This was supposed to be skipped:'
    $stderr.puts "test_false = '#{test_false}'"
  end
end


test_true = true
context 'Rspec Syntax' do
  context 'Bad Example to skip XML test', :if => !test_true do
    $stderr.puts 'This was supposed to be running:'
    $stderr.puts "test_true = '#{test_true}'"
  end
end

# the next example does not execute the intended guard command
context 'Rspec Syntax' do
  context 'Bad Example to skip XML test', :if => %x(ps ax | grep consu[l]) do
    $stderr.puts 'Running some test: '
    status = %x(ps ax | grep consu[l])
    $stderr.puts "Process check result: ps ax | grep consu[l] =>  '#{status}'"
  end
end

# the next example does execute the intended guard command. Need to be careful and chain calls
context 'Rspec Syntax' do
  context 'Bad Example to skip XML test', :if => Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?( 0 ) do
    $stderr.puts 'Running some test: '
    status = Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status
    $stderr.puts "Process check result: ps ax | grep consu[l] =>  '#{status}'"
  end
end
