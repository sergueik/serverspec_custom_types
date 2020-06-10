require 'spec_helper'

context 'shell functions with ssh' do
  # password-less login of the current user to localhost 
  # is the required setup
  # assumed to be performed manually
  # ssh-keygen
  # ssh-copy-id vagrant@localhost
  message = 'hello world'

  # white space and semicolons are significant
  describe command("ssh localhost -- 'test_cmd() { echo $@; }; test_cmd \"#{message}\"'") do
    its(:stdout) { should contain message }
    its(:exit_status) { should be 0 }
  end

  describe command("ssh localhost -- 'test_cmd() { echo $@; }; test_cmd \\\"#{message}\\\"'") do
    its(:stdout) { should contain "\"#{message}\"" }
    its(:exit_status) { should be 0 }
  end


  describe command("ssh localhost -- 'test_cmd() { echo $@ | tee /tmp/a.$$ > /dev/null; cat /tmp/a.$$; rm /tmp/a.$$; }; test_cmd \"#{message}\"'
") do
    its(:stdout) { should match Regexp.new("#{message}") }
    its(:exit_status) { should be 0 }
  end

end
