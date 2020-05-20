require 'spec_helper'
require 'fileutils'

context 'SpringBoot Jar tests' do
  jar_path = "/home/#{ENV.fetch('USER')}/src/springboot_study/basic-mysql/target"
  jar_filename = 'example.mysql.jar'

  tmp_path = '/tmp'
  xslt_file = "#{tmp_path}/transform.xsl"

  class_name = 'LoggerTest'
  source_file = "#{tmp_path}/#{class_name}.java"
  source_data = <<-EOF
    import org.apache.logging.log4j.LogManager;
    import org.apache.logging.log4j.Logger;

    public class #{class_name}{

      private static final Logger log = LogManager.getLogger(#{class_name}.class);

      private static final Logger logger = LogManager.getLogger("#{class_name}");
      public static void main(String[] args) {
        logger.info("Hello, World!");
      }
    }
  EOF
   before(:each) do
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
 describe command( <<-EOF
    cd #{tmp_path}
    jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/log4j-api
    jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/log4j-to-slf4j
    jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/slf4j-api
    cp BOOT-INF/lib/*jar .
    # javac -cp log4j-api-2.11.1.jar '#{class_name}.java'
    # java -cp log4j-api-2.11.1.jar:. '#{class_name}'
    for J in  $(ls -1 log4j-api-*.jar) ; do javac -cp $J '#{class_name}.java'; java -cp $J:. '#{class_name}' ; done
  EOF
  ) do
    its(:stdout) {  should contain 'extracted: BOOT-INF/lib/log4j-api' }
    its(:stderr) {  should contain 'Log4j2 could not find a logging implementation' }
    its(:stderr) {  should contain 'Using SimpleLogger to log to the console' }

  end
end

