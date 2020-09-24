require 'spec_helper'

context 'Whapping Command in Method test' do
  context 'broken example' do
    def jar_is_running(jar_name, argument)
      $stderr.puts "probing #{jar_name} and #{argument}"
      $stderr.puts "Running command: ps ax | grep '#{jar_name}' | grep -v 'grep' | sed 's|  *|\\n|g' | grep -q '#{argument}'"
      exit_status = command("ps ax | grep '#{jar_name}' | grep -v 'grep' | sed 's|  *|\\n|g'| grep -q '#{argument}'").exit_status
      $stderr.puts "Exit status:#{exit_status}"
      status =
        if exit_status == 0
          true
        else
          false
        end

      status
    end

    tomcat_version_major = '7'
    # Centos 7
    # sudo /usr/sbin/tomcat  start
    # do not put '-'
    option_present = 'Dcatalina.base=/usr/share/tomcat'
    jar_name = 'org.apache.catalina.startup.Bootstrap'
    option_missing = 'Dcatalina.base=/opt/tomcat'
    it "jar #{jar_name} is running with argument #{option_present}" do
      expect(jar_is_running(jar_name, option_present)).to be_truthy
    end
    it "jar #{jar_name} is not running with argument #{option_missing}" do
      expect(jar_is_running(jar_name, option_missing)).to be_falsey
    end
  end
end

