require 'spec_helper'
require 'find'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

# https://serverfault.com/questions/48109/how-to-find-files-with-incorrect-permissions-on-unix
context 'Springboot jar' do
   workspace = 'src' # on some nodes workspace = 'workspace'
  jar_path = "/home/#{ENV.fetch('USER')}/#{workspace}/springboot_study/basic-mysql/target"
  jar_filename = 'example.mysql.jar'
  tmp_path = '/tmp'

  message = 'Hello, Serverspec!'

  context 'Jar contents scan' do

    # NOTE: when parenthesis omitted,
    # unexpected keyword_do_block, expecting end-of-input
    # syntax error, unexpected keyword_do_block, expecting keyword_end

    describe command( <<-EOF
      jar tvf '#{jar_path}/#{jar_filename}' 2>&1 | grep '/$' | awk '{print $NF}'
    EOF
    ) do
      %w|
        org/springframework/
        org/springframework/boot/
        org/springframework/boot/loader/
        org/springframework/boot/loader/data/
        org/springframework/boot/loader/jar/
        org/springframework/boot/loader/archive/
        org/springframework/boot/loader/util/
        BOOT-INF/lib/
      |.each do |folder_name|
        its(:stdout) {  should contain folder_name }
      end
    end

    field = 3
    describe command  "jar tvf '#{jar_path}/#{jar_filename}' 2>&1 | grep 'BOOT-INF/lib' | cut -d '/' -f #{field} | sed 's|\\-[0-9][0-9.]*\\(RELEASE\\)*\\(Final\\)*\\.jar||g' " do
      %w|
        antlr
        aspectjweaver
        byte-buddy
        classmate
        dom4j
        hibernate-commons-annotations
        hibernate-core
        hibernate-validator
        HikariCP
        jackson-annotations
        jackson-core
        jackson-databind
        jackson-datatype-jdk8
        jackson-datatype-jsr310
        jackson-module-parameter-names
        jandex
        javassist-3.23.1-GA.jar
        javax.activation-api
        javax.annotation-api
        javax.persistence-api
        javax.transaction-api
        jaxb-api
        jboss-logging
        jul-to-slf4j
        log4j-api
        log4j-to-slf4j
        logback-classic
        logback-core
        mysql-connector-java
        slf4j-api
        snakeyaml
        spring-aop
        spring-aspects
        spring-beans
        spring-boot
        spring-boot-autoconfigure
        spring-boot-starter
        spring-boot-starter-aop
        spring-boot-starter-data-jpa
        spring-boot-starter-jdbc
        spring-boot-starter-json
        spring-boot-starter-logging
        spring-boot-starter-tomcat
        spring-boot-starter-validation
        spring-boot-starter-web
        spring-context
        spring-core
        spring-data-commons
        spring-data-jpa
        spring-expression
        spring-jcl
        spring-jdbc
        spring-orm
        spring-tx
        spring-web
        spring-webmvc
        tomcat-embed-core
        tomcat-embed-el
        tomcat-embed-websocket
        validation-api
     |.each do |jar_name|
       its(:stdout) {  should contain jar_name }
     end
   end
  end
  context 'partially successful run test' do

    class_name = 'TryLoggerTest'
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
      jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/log4j-api BOOT-INF/lib/log4j-to-slf4j BOOT-INF/lib/slf4j-api
      cp BOOT-INF/lib/*jar .
      for J in  $(ls -1 log4j-api-*.jar)
      do
        javac -cp $J '#{class_name}.java'
        java -cp $J:. '#{class_name}'
      done
    EOF
    ) do
      its(:stdout) {  should contain 'extracted: BOOT-INF/lib/log4j-api' }
      [
        'Log4j2 could not find a logging implementation',
        'Using SimpleLogger to log to the console'
      ].each do |line|
        its(:stderr) {  should contain line }
      end
      # when some needed jars are unavailable
      # log4j compains but does not throw exception nor return error
      its(:exit_status) { should eq 0 }
    end
  end

  # every springboot app carries some common jars in a similar fashion vanilla tomcat server do
  # demonstrate that one can extract those common jars from BOOT-INF/lib and compile the example exercising functionality from those
  # https://logging.apache.org/log4j/2.x/manual/api.html
  # https://www.eclipse.org/jetty/documentation/9.1.5.v20140505/example-logging-logback-centralized.html
  context 'SpringBoot Jar tests' do
    # NOTE: older SpringBoot releases like 1.4-x.RELEASE and disguised SB apps
    # did not follow this directory pattern
    #
    tmp_path = '/tmp'
    class_name = 'BetterLoggerTest'
    source_file = "#{tmp_path}/#{class_name}.java"
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
      # log4j no longer compains about missing jars
      [
        'Log4j2 could not find a logging implementation',
        'Using SimpleLogger to log to the console'
      ].each do |line|
        its(:stderr) {  should_not contain line }
      end
      its(:stdout) { should match /\[main\] INFO #{class_name} - #{message}/ }
      its(:exit_status) { should eq 0 }
    end
  end
  # https://www.baeldung.com/java-snake-yaml
  context 'basics of using snakeyaml' do
    class_name = 'SnakeYamliBasicTest'
    data = 'basic'
    source_file = "#{tmp_path}/#{class_name}.java"
    source_data = <<-EOF
      import java.io.FileInputStream;
      import java.io.IOException;
      import java.io.InputStream;
      import java.util.Map;

      import org.yaml.snakeyaml.Yaml;
      import org.yaml.snakeyaml.DumperOptions;
      import org.yaml.snakeyaml.DumperOptions.FlowStyle;

      public class #{class_name}{
        public static void main(String[] args) throws IOException {

          InputStream inputStream = new FileInputStream(args[0]);
          // https://www.programcreek.com/java-api-examples/org.yaml.snakeyaml.Yaml#11
          DumperOptions dumperOptions = new DumperOptions();
          dumperOptions.setDefaultFlowStyle(FlowStyle.BLOCK);
          // 	dumperOptions.setDefaultFlowStyle(FlowStyle.FLOW);
          Yaml yaml = new Yaml(dumperOptions);
          Map<String, Object> obj = yaml.loadAs(inputStream, Map.class);
          System.out.println(obj);
          // NOTE: dump produces no output
          yaml.dump(obj);
        }
      }
    EOF
    yaml_file = "#{tmp_path}/#{data}.yaml"
    yaml_data = <<-EOF
---
a: b
c:
 - 1
 - 2
 - 3
    EOF

    before(:each) do
      $stderr.puts "Writing #{source_file}"
      file = File.open(source_file, 'w')
      file.puts source_data
      file.close
      $stderr.puts "Writing #{yaml_file}"
      file = File.open(yaml_file, 'w')
      file.puts yaml_data
      file.close
    end
    describe command( <<-EOF
      cd #{tmp_path}
      jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/snakeyaml
      cp BOOT-INF/lib/snakeyaml*jar .
      for J in  $(ls -1 snakeyaml**.jar)
      do
        javac -cp $J '#{class_name}.java'
        java -cp $J:. '#{class_name}' '#{data}.yaml'
      done
    EOF
    ) do
      its(:stdout) { should contain 'a=b' }
      its(:exit_status) { should eq 0 }
    end

  end
  context 'using snakeyaml to validate yaml data' do
    class_name = 'SnakeYamlToolTest'
    source_file = "#{tmp_path}/#{class_name}.java"
    data = 'hieradata'
    source_data = <<-EOF
      import java.io.FileInputStream;
      import java.io.IOException;
      import java.io.InputStream;
      import java.util.Map;
      import java.util.Iterator;

      import org.yaml.snakeyaml.Yaml;
      import org.yaml.snakeyaml.DumperOptions;
      import org.yaml.snakeyaml.DumperOptions.FlowStyle;

      public class #{class_name}{
        private static final String branchName = "prod";
        public static void main(String[] args) throws IOException {

          InputStream inputStream = new FileInputStream(args[0]);
          Yaml yaml = new Yaml();
	  Map<String, Object> obj = yaml.loadAs(inputStream, Map.class);
          Iterator<String> hostIterator = obj.keySet().iterator();
          while (hostIterator.hasNext()) {
            String hostname = hostIterator.next();
            Map<String,Object>nodeConfig = (Map<String,Object>) obj.get(hostname);
            if (nodeConfig.containsKey("branch_name")
               &&
               nodeConfig.get("branch_name") != null
               &&
               nodeConfig.get("branch_name").toString().indexOf(branchName) == 0
               &&
               !nodeConfig.containsKey("service_account")
            ) {
               System.out.println(hostname);
            }
          }

        }
      }
    EOF
    yaml_file = "#{tmp_path}/#{data}.yaml"
    yaml_data = <<-EOF
---
host1.domain.com:
  dc: oxdc
  consul_name: transaction-server
  server_role: server
  branch_name: prod
  datacenter: oxmoor
  user: root
  service_account: tomcat
  servergroup: transactions
host2.domain.com:
  dc: oxdc
  consul_name: transaction-server
  server_role: server
  branch_name: prod
  datacenter: oxmoor
  user: root
 # service_account: tomcat
  servergroup: transactions
host3.domain.com:
  dc: oxdc
  consul_name: transaction-server
  server_role: server
  branch_name: prod
  datacenter: oxmoor
  user: root
  service_account: tomcat
  servergroup: transactions
host3.domain.com:
  dc: oxdc
  datacenter: oxmoor
  some_other_data: 123
    EOF

    before(:each) do
      $stderr.puts "Writing #{source_file}"
      file = File.open(source_file, 'w')
      file.puts source_data
      file.close
      $stderr.puts "Writing #{yaml_file}"
      file = File.open(yaml_file, 'w')
      file.puts yaml_data
      file.close
    end
    describe command( <<-EOF
      cd #{tmp_path}
      jar xvf '#{jar_path}/#{jar_filename}' BOOT-INF/lib/snakeyaml
      cp BOOT-INF/lib/snakeyaml*jar .
      for J in  $(ls -1 snakeyaml**.jar)
      do
        javac -cp $J '#{class_name}.java'
        java -cp $J:. '#{class_name}' '#{data}.yaml'
      done
    EOF
    ) do
      its(:stderr) { should_not contain 'java.io.FileNotFoundException' }
      its(:stderr) { should_not contain 'java.lang.NullPointerException' }
      its(:stdout) { should contain 'host2.domain.com' }
      its(:exit_status) { should eq 0 }
      describe file "#{tmp_path}/#{class_name}.class" do
        it {should exist}
      end
    end

  end
end
