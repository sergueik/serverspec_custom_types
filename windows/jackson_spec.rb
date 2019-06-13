require_relative '../windows_spec_helper'
# require 'spec_helper'


context 'Jackson YAML', :if => os[:family] == 'windows' do

  # based on: https://dzone.com/articles/read-yaml-in-java-with-jackson
  java_version = '1.8.0_101'
  # expect dependency jars to be somehow present in #{target_lib_path}
  jars = [
    'commons-lang3-3.0.1.jar',
    'jackson-annotations-2.9.9.jar',
    'jackson-core-2.9.9.jar',
    'jackson-databind-2.9.9.jar',
    'jackson-dataformat-yaml-2.9.9.jar',
    'log4j-api-2.5.jar',
    'log4j-core-2.5.jar',
    'snakeyaml-1.24.jar', # dependency of the jackson jar!
  ]
  path_separator = ';'
  target_lib_path = 'target/lib' # using default maven package install command to set up the environment
  jars_cp = jars.collect{|jar| "#{target_lib_path}/#{jar}"}.join(path_separator)
  database_host = 'localhost'
  database_name = 'information_schema'
  username = 'root'
  password = 'password'

  class_name = 'JacksonExample'

  source = <<-EOF

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
    public class #{class_name} {

    private static boolean debug = false;

    private static final String dataFileName = "user.yaml";
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
  describe command(<<-EOF
    pushd $env:USERPROFILE
    write-output '#{source}' | out-file #{class_name}.java -encoding ASCII
    $env:PATH = "${env:PATH};c:\\java\\jdk#{java_version}\\bin"
    # javac -cp target\\lib\\* JacksonExample.java
    javac -cp target\\lib\\* '#{class_name}.java'
    # would produce
    # '#{class_name}$User.class'
    # '#{class_name}.class'
    cmd %%- /c "java -cp #{jars_cp}#{path_separator}. #{class_name}"
  EOF
  ) do
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
