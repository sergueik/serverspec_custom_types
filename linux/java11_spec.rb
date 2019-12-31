require 'spec_helper'
require 'fileutils'

context 'Java 11 source tests' do
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