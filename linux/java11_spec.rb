require 'spec_helper'
require 'fileutils'
context 'Java 11' do
  context 'source tests' do
    tmp_path = '/tmp/example'
    class_name = 'FileWalkTest'
    source_file = class_name.downcase
    # TODO: how to combine options with env?
    #  #!/bin/env java --source 11
    #  /bin/env: java --source 11: No such file or directory
    source = <<-EOF
  #!/bin/java --source 11
      /*
        NOTE: can not use shell comments beyond the  first line
      */

      import static java.lang.System.out;
      import java.nio.file.Paths;
      import java.nio.file.Files;

      public class #{class_name}{
        public static void main(String[] args) throws Exception {
          if (args.length > 0){
            Files.walk(Paths.get(args[0])).forEach(out::println);
          }
        }
      }
    EOF
    describe command(<<-EOF
      mkdir -p #{tmp_path}
      1>/dev/null 2>/dev/null pushd #{tmp_path}
      echo '#{source}' > #{source_file}
      chmod +x #{source_file}
      ./#{source_file} .
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain "#{tmp_path}/#{source_file}" }
      its(:stderr) { should be_empty }
      its(:stderr) { should_not contain 'Could not create the Java Virtual Machine'}
      its(:stderr) { should_not contain 'A fatal exception has occurred'}

    end
  end
  context 'Jar module-info' do
    jarfile = 'example.app@1.0.jar'
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd #{tmp_path}
      jar xvf '#{jarfile}' module-info.class; strings module-info.class
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      # from jar
      [
        'inflated: module-info.class'
      ].each do |line|
        its(:stdout) { should contain line }
      end
      # from strings
      [
        'module-info.java',
        'ModulePackages',
        'ModulePackages'
      ].each do |line|
        its(:stdout) { should contain line }
      end
      its(:stderr) { should be_empty }
    end

  end
end

