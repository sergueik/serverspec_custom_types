require_relative '../windows_spec_helper'

# require 'spec_helper'

require 'fileutils'

$DEBUG = ENV.fetch('DEBUG', 'false')
$stderr.puts "Literal $DEBUG='#{$DEBUG}'"
$DEBUG = (ENV.fetch('DEBUG', 'false') =~ /^(true|t|yes|y|1)$/i)
$stderr.puts "Evaluated $DEBUG='#{$DEBUG ? 'true': 'false'}'"

context 'Jackson YAML', :if => os[:family] == 'windows' do

  # based on: https://dzone.com/articles/read-yaml-in-java-with-jackson
  java_version = '1.8.0_101'
  # expect dependency jars to be somehow present in #{target_lib_path}
  jackson_version = '2.9.9'
  commons_lang3_version = '3.0.1'
  log4j_version = '2.5'
  snakeyaml_version = '1.24'
  jars = [
    "commons-lang3-#{commons_lang3_version}.jar",
    "jackson-annotations-#{jackson_version}.jar",
    "jackson-core-#{jackson_version}.jar",
    "jackson-databind-#{jackson_version}.jar",
    "jackson-dataformat-yaml-#{jackson_version}.jar",
    "log4j-api-#{log4j_version}.jar",
    "log4j-core-#{log4j_version}.jar",
    "snakeyaml-#{snakeyaml_version}.jar", # dependency of the jackson jar!
  ]
  path_separator = ';'
  target_lib_path = 'target/lib' # using default maven package install command to set up the environment
  jars_cp = jars.collect{|jar| "#{target_lib_path}/#{jar}"}.join(path_separator)

  homedir = ENV.fetch('USERPROFILE', 'c:/Users/Vagrant')
  yaml_filename = 'user.yaml'
  yaml_data = <<-EOF
---
name: Test User
age: 30
address:
  line1: My Address Line 1
  line2: ~
  city: Washington D.C.
  zip: 20000
roles:
  - User
  - Editor
  EOF
  java_class_name = 'JacksonExample'

  java_source = <<-EOF

  import java.util.Arrays;
  import java.util.Map;
  import java.io.File;

  import org.apache.logging.log4j.LogManager;
  import org.apache.logging.log4j.Logger;

  import com.fasterxml.jackson.databind.ObjectMapper;
  import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
  import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;

  import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
  import org.apache.commons.lang3.builder.ToStringStyle;
    public class #{java_class_name} {

    private static boolean debug = false;

    private static final String dataFileName = "#{yaml_filename}";
    private static final YAMLFactory yamlFactory = new YAMLFactory();
    static {
      yamlFactory.configure(YAMLGenerator.Feature.USE_NATIVE_TYPE_ID, false)
          .configure(YAMLGenerator.Feature.MINIMIZE_QUOTES, true)
          .configure(YAMLGenerator.Feature.ALWAYS_QUOTE_NUMBERS_AS_STRINGS, true);
    }
    private static ObjectMapper objectMapper = new ObjectMapper(yamlFactory);

    private static String yamlString = null;

    private static final Logger log = LogManager.getLogger(JacksonExample.class);

    public static void main(String[] args) {

      try {
        User user = objectMapper
            .readValue(new File(String.join(System.getProperty("file.separator"),
                Arrays.asList(System.getProperty("user.dir"), dataFileName))),
                User.class);
        System.out.println(ReflectionToStringBuilder.toString(user,
            ToStringStyle.MULTI_LINE_STYLE));
      } catch (Exception e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }

    private static class User {
      private String name;
      private int age;
      private Map<String, String> address;
      private String[] roles;

      public String getName() {
        return name;
      }

      public void setName(String data) {
        this.name = data;
      }

      public int getAge() {
        return age;
      }

      public void setAge(int data) {
        this.age = data;
      }

      public Map<String, String> getAddress() {
        return address;
      }

      public void setAddress(Map<String, String> data) {
        this.address = data;
      }

      public String[] getRoles() {
        return roles;
      }

      public void setRoles(String[] data) {
        this.roles = data;
      }
    }
  }
  EOF
  before(:each) do
    $stderr.puts "Writing #{yaml_filename}"
    file = File.open("#{homedir}/#{yaml_filename}", 'w')
    file.puts yaml_data
    file.close
    $stderr.puts "Writing #{java_class_name}"
    file = File.open("#{homedir}/#{java_class_name}.java", 'w')
    file.puts java_source
    file.close
  end

  describe command(<<-EOF
    pushd '#{homedir}'
    $env:PATH = "${env:PATH};c:\\java\\jdk#{java_version}\\bin"
    javac -cp -cp #{jars_cp} '#{java_class_name}.java'
    cmd %%- /c "java -cp #{jars_cp}#{path_separator}. #{java_class_name}"
  EOF
  ) do
    [
      "#{homedir}/#{java_class_name}$User.class",
      "#{homedir}/#{java_class_name}.class"
    ].each do |class_file|
      describe file(class_file) do
        it { should be_file }
      end
    end
    its(:exit_status) { should eq 0 }
    [
      'name=Test User',
      'age=30',
      'address={line1=My Address Line 1, line2=null, city=Washington D.C., zip=20000}',
      'roles={User,Editor}',
    ].each do |line|
      its(:stdout) { should match line}
    end
  end
end
