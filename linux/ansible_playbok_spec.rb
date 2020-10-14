require 'spec_helper'

context 'ansible paybook' do
  # sudo -H pip3 install  pyyaml --upgrade
  context 'Playbook YAML validation' do
    tmp_path = '/tmp'
    script_file = "#{tmp_path}/a.py"
    # NOTE: indent-sensitive
    script_data = <<-EOF
import yaml
import sys
import pprint
input_file = sys.argv[1]
f = open(input_file)
playbook = yaml.load(f, Loader=yaml.FullLoader)
pp = pprint.PrettyPrinter(indent=2)
# pp.pprint(playbook)
pp.pprint(playbook['tasks'][0]['package'])
try:
  pp.pprint(playbook['tasks'][0]['package']['name'])
except TypeError as e:
  print(str(e), file = sys.stderr)
  # string indices must be integers
  pass
    EOF
    tmp_path = '/tmp'
    playbook_file = "#{tmp_path}/playbook.yaml"
    # NOTE: indent-sensitive
    playbook_data = <<-EOF
---
hosts: all
become: true
tasks:
  - name: install
    package: name=jdk             
    EOF
    before(:each) do
      $stderr.puts "Writing #{playbook_file}"
      file = File.open(playbook_file, 'w')
      file.puts playbook_data
      file.close
      $stderr.puts "Writing #{script_file}"
      file = File.open(script_file, 'w')
      file.puts script_data
      file.close
    end
    describe command(<<-EOF
      python3 #{script_file} #{playbook_file}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should contain 'string indices must be integers' }
      # exception will be thrown
      # because the value of playbook['tasks'][0]['package'] is tokenized by ansible not yaml
      its(:stdout) { should contain "'name=jdk'"}
    end
  end
end
