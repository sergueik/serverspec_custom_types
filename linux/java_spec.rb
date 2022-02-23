if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'Common test' do
  path_separator = ':'
  java_version = '1.8.0_161'
  jdk_path = "/opt/jdk#{java_version}"
  jar_path = "#{jdk_path}/lib"
  jar = 'tools.jar'
  jars_cp =  "#{jar_path}/#{jar}"
  tmp_path = '/tmp'
  package_name = 'example'
  class_name = 'Basic'
  source_file = "#{tmp_path}/#{class_name}.java"
  class_file = "#{tmp_path}/#{package_name}/#{class_name}.class"
  source_data = <<-EOF
package #{package_name};
public class #{class_name} {
	public static void main(String[] argv) throws Exception {
          System.out.println("test");
	}
}

  EOF
  before(:each) do
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
  describe command(<<-EOF
    cd '#{tmp_path}'
    export CLASSPATH=#{jars_cp}#{path_separator}.
    javac -d . -cp #{jars_cp} '#{source_file}'
    java -cp #{jars_cp}#{path_separator}. '#{package_name}.#{class_name}'
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    [
      'test',
    ].each do |line|
      its(:stdout) { should contain line }
    end
    describe file class_file do
      it { should be_file }
    end
  end
end
