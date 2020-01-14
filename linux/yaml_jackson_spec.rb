require 'spec_helper'
require 'pp'
require 'fileutils'

context 'Using jq and a bundle of jackson jars to traverse YAML' do
  datafile = '/tmp/example.yaml'
  before(:each) do
    # NOTE: indent and white space matters
    Specinfra::Runner::run_command( <<-EOF
      cat<<END>'#{datafile}'
---
foo: details about foo
baz:
  - a
  - b
END
    EOF
    )
  end
  catalina_home = '/opt/tomcat'
  path_separator = ':'
  application = 'Tomcat Application Name'
  jar_path = "#{catalina_home}/webapps/#{application}/WEB-INF/lib/"

  class_name = 'YAML2JSON'
  source_file = "#{class_name}.java"
  source = <<-EOF

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.core.JsonFactory;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

public class YAML2JSON {
	public static void main(String[] args) throws Exception {

		BufferedReader br = new BufferedReader(new FileReader(new File(args[0])));
		StringBuffer sb = new StringBuffer();
		String line;
		while ((line =  br.readLine()) != null) {
			sb.append(line).append("\\\\n");
		}
		System.out.println(convertYamlToJson(sb.toString()));
	}

	private static String convertYamlToJson(String data) throws Exception {
		Object obj = (new ObjectMapper(new YAMLFactory())).readValue(data, Object.class);
		return (new ObjectMapper()).writeValueAsString(obj);
	}
}

  EOF
  tmp_path = '/tmp'
  jars_compile = 'jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar'
  jars_run = 'jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar:jackson-annotations-2.9.9.jar:snakeyaml-1.24.jar'
  # based on https://stackoverflow.com/questions/23744216/how-do-i-convert-from-yaml-to-json-in-java
  # assumed no Ruby or Python present / allowed on the machine
  #
  # xmllint --xpath '//*[local-name() = "artifactId"][contains(text() , "jackson-core")]/..' ../../selenium_tests/pom.xml
  # xmllint --xpath '//*[local-name() = "artifactId"][contains(text() , "jackson-dataformat-yaml")]/..' ../../selenium_tests/pom.xml
  # to compile need only
  # javac -cp jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar:. YAML2JSON.java
  # to run need a longer set of jars, but typically all found in a spring app
  # java -cp jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar:jackson-annotations-2.9.9.jar:snakeyaml-1.24.jar:.
  # javac -cp jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar:. YAML2JSON.java
  # java -cp jackson-databind-2.9.9.3.jar:jackson-dataformat-yaml-2.9.9.jar:jackson-core-2.9.9.jar:jackson-annotations-2.9.9.jar:snakeyaml-1.24.jar:. YAML2JSON
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    echo '#{source}' > '#{source_file}'
    javac -cp #{jars_compile}#{path_separator}. '#{source_file}'
    export CLASSPATH=#{jars_run}#{path_separator}.
    java -cp #{jars_run}#{path_separator}. '#{class_name}' '#{datafile}' |\\
    jq '.foo'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match Regexp.new('foo: details about foo', Regexp::IGNORECASE) }
    its(:stderr) { should_not match 'jq: error: syntax error' }
  end
end
