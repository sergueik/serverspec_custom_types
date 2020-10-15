require 'spec_helper'

context 'ansible paybook' do
  # sudo -H pip3 install  pyyaml --upgrade
  context 'Playbook YAML validation' do
    tmp_path = '/tmp'
    playbook_file = "#{tmp_path}/playbook.yaml"
    # NOTE: indent-sensitive
    playbook_data = <<-EOF
---
hosts: all
become: true
tasks:
  - name: install
    package: name=jdk state=installed
    EOF
    context 'No shorthand notation' do
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
        # because the value of the "ansible shorthand notation" expression
        # playbook['tasks'][0]['package'] is tokenized by ansible not yaml
        its(:stdout) { should contain "'name=jdk state=installed'"}
      end
    end
    context 'with shorthand notation' do
      script_file = "#{tmp_path}/b.py"
      # NOTE: indent-sensitive
      script_data = <<-EOF
import yaml
import sys
import pprint
input_file = sys.argv[1]
f = open(input_file)
playbook = yaml.load(f, Loader=yaml.FullLoader)
pp = pprint.PrettyPrinter(indent=2)

try:
  data = playbook['tasks'][0]['package']
  pp.pprint(data)
  values = dict(item.split('=') for item in data.split('  *'))
  pp.pprint(values['name'])
  pp.pprint(values['state'])
except TypeError as e:
  print(str(e))
  # string indices must be integers
  # because the value of the package is tokenized by ansible not yaml
  pass
except ValueError as e:
  print(str(e))
  # TODO: ValueError: dictionary update sequence element #0 has length 3; 2 is required
  pass
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
        its(:stderr) { should be_empty }
        [
          'jdk',
          'installed'
        ].each do |value|
          its(:stdout) { should contain(value)}
        end
      end
    end
  end
  context 'beyond playbook YAML validation' do
    # it is uncertain if the Ansible is actuaally using / capable of
    # the following "ultra-short hand notation" YAML
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
  - name: install
    package: name=tomcat state=instaled
  - name: service
    package: name='tomcat server' state=running comment='more custom data with spaces'
    EOF
    script_file = "#{tmp_path}/c.py"
    # NOTE: indent-sensitive
    script_data = <<-EOF
import yaml
import sys
import pprint
import re

DEBUG = False
pp = pprint.PrettyPrinter(indent = 2)
# TODO: captures values with a space inside single quotes
# except leading and trailing space in the value
# pattern = re.compile(r"'([^=']+ [^=']+)'")
tokenizer_expression = "'(?P<word>[^=']+ [^=']+)'" # no need for 'raw'

playbook = yaml.load(open(sys.argv[1]), Loader=yaml.FullLoader)
if DEBUG:
  pp.pprint(playbook)
tasks = playbook['tasks']
for cnt in range(len(tasks)):
  task = tasks[cnt]

  if DEBUG:
    pp.pprint(task['package'])
  try:
    data = task['package']
    if DEBUG:
      pp.pprint(data)

    pattern = re.compile(tokenizer_expression)
    total_cnt = 0
    new_data = data
    # https://stackoverflow.com/questions/3345785/getting-number-of-elements-in-an-iterator-in-python
    if DEBUG:
      for matches in re.finditer(pattern, data):
        total_cnt = total_cnt + 1
        print('found: "{}"'.format( matches.group(1)))
    else:
      total_cnt =  sum(1 for _ in re.finditer(pattern, data))

    for cnt in range(total_cnt):
      matches = pattern.search( data )
      if matches != None:
        word = matches.group('word')
        if ' ' in word:
          new_word = word.replace(' ', '0x20')
          if DEBUG:
            print('processing "{}"'.format(word))
          new_data = data.replace("'{}'".format(word), "'{}'".format(new_word))
        else:
          new_data = data
      if DEBUG:
        print('temporary data (iteration {}): "{}"'.format(cnt, new_data))
      data = new_data
    values = {}
    raw_values = dict(item.split('=') for item in new_data.split(' '))
    for k in raw_values:
      values[k] = raw_values[k].replace('0x20', ' ').replace("'", '')
    subkey = 'name'
    print('{}="{}"'.format(subkey, values[subkey]))
  except TypeError as e:
    print(str(e), file = sys.stderr)
    pass
  except ValueError as e:
    print(str(e), file = sys.stderr)
    # TODO: ValueError: dictionary update sequence element #0 has length 3; 2 is required
    pass
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
      its(:stderr) { should be_empty }
      [
        'jdk',
        'tomcat',
        'tomcat server',
      ].each do |value|
        its(:stdout) { should contain(value)}
      end
    end
  end
end

