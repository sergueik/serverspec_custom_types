require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

context 'Java 11' do

  context 'new binaries' do
    # the jshell and few other binaries are only available starting with JDK 9,
    # absent from JDK 8
    context 'jshell' do
      describe command(<<-EOF
        TMPFILE=/tmp/a$$.txt
        echo $(dirname  $(readlink  $(readlink $(which java ))))| tee $TMPFILE
        cat $TMPFILE| while read JAVA_REAL_BIN_PATH ; do
          cd $JAVA_REAL_BIN_PATH
          find . -maxdepth 1 -name 'jshell'
        done
        ./jshell --version
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /\/jdk-11.[0-9.]+\/bin/ }
        its(:stdout) { should contain './jshell' }
        its(:stdout) { should match /jshell 11.[0-9]+$/ }
        its(:stderr) { should be_empty }
      end
    end
    context 'jmod' do
      describe command(<<-EOF
        TMPFILE=/tmp/a$$.txt
        echo $(dirname  $(readlink  $(readlink $(which java ))))| tee $TMPFILE
        cat $TMPFILE| while read JAVA_REAL_BIN_PATH ; do
          cd $JAVA_REAL_BIN_PATH
          find . -maxdepth 1 -name 'jmod'
        done
        ./jmod --version
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /\/jdk-11.[0-9.]+\/bin/ }
        its(:stdout) { should contain './jmod' }
        its(:stdout) { should match /11.[0-9]+$/ }
        its(:stderr) { should be_empty }
      end
    end
  end
  context 'source tests' do
    class_name = 'FileWalkTest'
    source_file = class_name.downcase
    # TODO: how to combine options with env?
    #  #!/bin/env java --source 11
    #  /bin/env: java --source 11: No such file or directory
    source = <<-EOF
  #!/bin/java --source 11
      /*
        NOTE: should switch from shell to java comments beyond the first line
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
    tmp_path = '/tmp/example'
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
  context 'Jar module-info.java class component' do
    jarfile = 'example.app@1.0.jar'
    tmp_path = '/tmp/example'
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd #{tmp_path}
      jar xvf '#{jarfile}' module-info.class;
      # can also use strings
      javap -v module-info.class;
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
        'ModuleMainClass'
      ].each do |line|
        its(:stdout) { should contain line }
      end
      its(:stderr) { should be_empty }
    end
    # TODO: java --describe-module
    # TODO: java --dry-run
    # TODO: jdeps
  end
end


