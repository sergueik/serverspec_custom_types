require 'spec_helper'
require 'fileutils'

context 'SpringBoot Jar tests' do
  jar_path = "/home/#{ENV.fetch('USER')}/src/springboot_study/basic-mysql/target"
  jar_filename = 'example.mysql.jar'

  tmp_path = '/tmp'
  message = 'Hello, Serverspec!'
  class_name = 'LoggerTest'
  source_file = "#{tmp_path}/#{class_name}.java"
  # https://logging.apache.org/log4j/2.x/manual/api.html
  # https://www.eclipse.org/jetty/documentation/9.1.5.v20140505/example-logging-logback-centralized.html
  source_data = <<-EOF
    import org.apache.logging.log4j.LogManager;
    import org.apache.logging.log4j.Logger;

    public class #{class_name}{
      private static final Logger logger = LogManager.getLogger("#{class_name}");
      public static void main(String[] args) {
        logger.info("#{message}");
      }
    }
  EOF
  before(:each) do
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
  # every springboot app carries some common jars in a similar fashion vanilla tomcat server do
  # demonstrate that one can extract those common jars from BOOT-INF/lib and compile the example exercising functionality from those
  describe command( <<-EOF
    cd #{tmp_path}
    jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/log4j-api BOOT-INF/lib/log4j-to-slf4jBOOT-INF/lib/slf4j-api BOOT-INF/lib/logback-
    cp BOOT-INF/lib/log4j-api-*jar .
    for J in  $(ls -1 log4j-api-*.jar) ; do 
      javac -cp $J '#{class_name}.java'; 
    done
    java -cp .:BOOT-INF/lib/* '#{class_name}'
  EOF
  ) do
    its(:stdout) { should contain 'extracted: BOOT-INF/lib/log4j-api' }
    # when some needed jars are unavailable
    # log4j compains but does not throw exception
    # however we avoided that now
    its(:stderr) { should_not contain 'Log4j2 could not find a logging implementation' }
    its(:stderr) { should_not contain 'Using SimpleLogger to log to the console' }
    its(:stdout) { should match /\[main\] INFO #{class_name} - #{message}/ }
    its(:exit_status) { should eq 0 }
  end
end


