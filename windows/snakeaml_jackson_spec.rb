require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

# require 'spec_helper'

require 'fileutils'

$DEBUG = ENV.fetch('DEBUG', false)

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
    "snakeyaml-#{snakeyaml_version}.jar", # dependency of the jackson jar!
  ]
  path_separator = ';'
  target_lib_path = 'target/lib' # using default maven package install command to set up the environment
  jars_cp = jars.collect{|jar| "#{target_lib_path}/#{jar}"}.join(path_separator)

  homedir = ENV.fetch('USERPROFILE', 'c:/Users/Vagrant')
  yaml_filename = 'user.yaml'
  yaml_data = <<-EOF
---
# https://learnxinyminutes.com/docs/yaml/
person: &person
  'familyname': 'John Doe'
  age: 30
  address:
    line1: My Address Line 1
    line2: ~
    city: Washington D.C.
    zip: 20000
user:
  name: Test User
  <<: *person
  roles:
    - User
    - Editor
  EOF
  java_class_name = 'SnakeYamlJacksonExample'

  java_source = <<-EOF

  import java.util.ArrayList;
  import java.util.Arrays;
  import java.util.Collections;
  import java.util.HashMap;
  import java.util.List;
  import java.util.Map;

  import java.io.File;
  import java.io.IOException;
  import java.io.InputStream;
  import java.nio.file.Files;
  import java.nio.file.Paths;

  import org.yaml.snakeyaml.Yaml;

  import com.fasterxml.jackson.core.type.TypeReference;
  import com.fasterxml.jackson.databind.ObjectMapper;
  import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
  import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;

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

    public static void main(String[] args) {
      InputStream in;
      try {
        // load with snakeyaml
        in = Files.newInputStream(Paths.get(dataFileName));
        Map<String, Object> data = (Map<String, Object>) new Yaml().load(in);
        Map<String, Object> userData = (Map<String, Object>) data.get("user");
        ArrayList<String> roles = (ArrayList<String>) userData.get("roles");
        User user = new User((String) userData.get("name"),
            (String) userData.get("familyname"), (int) userData.get("age"),
            (Map<String, Object>) userData.get("address"),
            (String[]) roles.toArray(new String[roles.size()]));
        // dump with Jackson
        yamlString = objectMapper.writeValueAsString(user);
        System.out.println(String.format(
            "Cherry-picking the user with SnakeYaml and Jackson: \\n%s\\n",
            yamlString));

      } catch (IOException e) {
        System.err.println("Exception (ignored): " + e.toString());
      }
    }
    private static class User {

      private String name;
      private String familyname;
      private int age;
      private Map<String, Object> address;
      private String[] roles;

      public String getFamilyname() {
        return familyname;
      }

      public void setFamilyname(String data) {
        this.familyname = data;
      }

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

      public Map<String, Object> getAddress() {
        return address;
      }

      public void setAddress(Map<String, Object> data) {
        this.address = data;
      }

      public String[] getRoles() {
        return roles;
      }

      public void setRoles(String[] data) {
        this.roles = data;
      }

      // default constructor neeeded for jackson
      public User() {

      }

      public User(String name, String familyname, int age,
          Map<String, Object> address, String[] roles) {
        super();
        this.name = name;
        this.familyname = familyname;
        this.age = age;
        this.address = address;
        this.roles = roles;
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
    javac -cp target/lib/* '#{java_class_name}.java'
    # javac -cp -cp #{jars_cp} '#{java_class_name}.java'
    cmd %%- /c "java -cp #{jars_cp}#{path_separator}. #{java_class_name}"
  EOF
  ) do
    [
      java_class_name,
      "#{java_class_name}$User"
    ].each do |class_file|
      describe file("#{homedir}/#{class_file}.class") do
        it { should be_file }
      end
    end
    # Note: SnakeYamlJacksonExample.java uses unchecked or unsafe operations.
    # Note: Recompile with -Xlint:unchecked for details.
    # its(:exit_status) { should eq 0 }
result_yaml = <<-EOF
name: Test User
familyname: John Doe
age: 30
address:
  line1: My Address Line 1
  line2: null
  city: Washington D.C.
  zip: 20000
roles:
- User
- Editor
EOF
    result_yaml.split(/\r?\n/).each do |line|
      its(:stdout) { should contain line.strip }
    end
  end
end
