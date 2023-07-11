require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

context 'Strongly typed Object deserialziation' do

  catalina_home = '/opt/tomcat'
  path_separator = ':'
  # gson being one of de facto standard JSON processors
  # is likely present in tomcat lib directory when app is deployed in tomcat container
  # or in or some flexible 'lib' under the app directory for a standalone springboot app
  app_name = '<application>'
  jar_path = "#{catalina_home}/webapps/#{app_name}/WEB-INF/lib/"
  app_base_path = "/opt/#{app_name}/snandalone/lib"
  jar_path = "#{app_base_path}/lib"
  jar_path = '/tmp'

  # environment-specific jar version: 
  # slower environments (like e.g. PROD) typically have older revisions
  jar_versions = (ENV.fetch('ENV', 'dev').upcase =~ (/^(UAT|PROD)$/i)) ?  { 'gson' => '2.7', } : { 'gson' => '2.8.5', }

  jar_search_string = '(' + jar_versions.keys.join('|') + ')'
  jars = []
  jar_versions.each do |artifactid,version|
    jars.push artifactid + '-' + version + '.jar'
  end
  jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)
  tmp_path = '/tmp'
  context 'Example 1' do
    json_file = "#{tmp_path}/example.json"
    # parse error: Invalid numeric literal at line 2, column 62
    json_data = <<-EOF
      {
        "title" : "Macbook \\" Laptop",
        "price" : 325.0,
        "url" : "https://miami.craigslist.org/pbc/sys/d/west-palm-beach-macbook-pro-a1278-c2d/6943935079.html",
        "id" : "32a1a243-170e-4948-b39b-1c54a03925d9"
      }
    EOF
    class_name = 'TestJSONDeserialize'
    source_file = "#{tmp_path}/#{class_name}.java"
    source_data = <<-EOF

      import java.io.IOException;
      import java.io.InputStream;

      import java.io.IOException;
      import java.io.File;
      import java.io.FileReader;
      import java.io.InputStream;
      import java.io.InputStreamReader;
      import java.io.Reader;
      import java.lang.reflect.Type;
      import java.nio.file.Files;
      import java.nio.file.Paths;
      import java.util.ArrayList;
      import java.util.LinkedHashMap;
      import java.util.List;

      import java.util.UUID;

      import com.google.gson.Gson;
      import com.google.gson.GsonBuilder;
      import com.google.gson.JsonElement;
      import com.google.gson.JsonObject;
      import com.google.gson.JsonPrimitive;
      import com.google.gson.JsonSerializationContext;
      import com.google.gson.JsonSerializer;
      import com.google.gson.JsonSyntaxException;
      import com.google.gson.reflect.TypeToken;


      public class #{class_name} {

        public static void main(String[] argv) throws Exception {
            String fileName = "#{json_file}";

            Gson parser = new Gson();
            InputStream in = Files.newInputStream(Paths.get(fileName));
            String jsonString = readFully(new InputStreamReader(in));
            System.err.println("Processing JSON: " + jsonString);
            Type type = new TypeToken<ObjectItem>() { }.getType();
            try {
              // create json parser
              ObjectItem data = parser.fromJson(jsonString, type);
              // parse data to
              System.err.println("Processing Object: " + data.getTitle());
            } catch (JsonSyntaxException e) {
              System.err.println("Exception (ignored) " + e.toString());
            }

        }
        public static String readFully(Reader reader) throws IOException {
          char[] arr = new char[0x200];
          StringBuffer stringBuffer = new StringBuffer();
          int numChars;

          while ((numChars = reader.read(arr, 0, arr.length)) > 0) {
              stringBuffer.append(arr, 0, numChars);
          }
          return stringBuffer.toString();
        }

        public static class ObjectItem {
          private String title;
          private Float price;
          private String url;
          private String id = null;

          public String getTitle() {
            return title;
          }

          public void setId(String data) {
            this.id = data;
          }

          public String getId() {
            return id;
          }

          public void setTitle(String data) {
            this.title = data;
          }

          public Float getPrice() {
            return price;
          }

          public void setPrice(Float data) {
            this.price = data;
          }

          public String getUrl() {
            return url;
          }

          public void setUrl(String data) {
            this.url = data;
          }

          private static final String staticInfo = "static info";

          public static String getStaticInfo() {
            return staticInfo;
          }

          public ObjectItem() {
            id = UUID.randomUUID().toString();
          }

        }
      }
    EOF
    before(:each) do
      $stderr.puts "Writing #{json_file}"
      file = File.open(json_file, 'w')
      file.puts json_data
      file.close
      $stderr.puts "Writing #{source_file}"
      file = File.open(source_file, 'w')
      file.puts source_data
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      export CLASSPATH=#{jars_cp}#{path_separator}.
      javac -cp #{jars_cp} '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      sleep 3
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      [
        'Processing JSON',
        'Processing Object',
      ].each do |line|
        its(:stderr) { should contain line }
      end
    end
  end
  context 'Example 2: Hash of custom objects' do
    json_file = "#{tmp_path}/example.json"
    # parse error: Invalid numeric literal at line 2, column 62
    json_data = <<-EOF
      {
        "data":
          {
            "title" : "Macbook \\" Laptop",
            "price" : 325.0,
            "url" : "https://miami.craigslist.org/pbc/sys/d/west-palm-beach-macbook-pro-a1278-c2d/6943935079.html",
            "id" : "32a1a243-170e-4948-b39b-1c54a03925d9"
          },
        "other":
          {
            "title" : "Macbook \\" Laptop",
            "price" : 325.0,
            "url" : "https://miami.craigslist.org/pbc/sys/d/west-palm-beach-macbook-pro-a1278-c2d/6943935079.html",
            "id" : "32a1a243-170e-4948-b39b-1c54a03925d9"
          }
      }
    EOF
    class_name = 'TestJSONObjectsHash'
    source_file = "#{tmp_path}/#{class_name}.java"
    source_data = <<-EOF

      import java.io.IOException;
      import java.io.InputStream;

      import java.io.IOException;
      import java.io.File;
      import java.io.FileReader;
      import java.io.InputStream;
      import java.io.InputStreamReader;
      import java.io.Reader;
      import java.lang.reflect.Type;
      import java.nio.file.Files;
      import java.nio.file.Paths;
      import java.util.ArrayList;
      import java.util.LinkedHashMap;
      import java.util.List;
      import java.util.Map;


      import java.util.UUID;

      import com.google.gson.Gson;
      import com.google.gson.GsonBuilder;
      import com.google.gson.JsonElement;
      import com.google.gson.JsonObject;
      import com.google.gson.JsonPrimitive;
      import com.google.gson.JsonSerializationContext;
      import com.google.gson.JsonSerializer;
      import com.google.gson.JsonSyntaxException;
      import com.google.gson.reflect.TypeToken;


      public class #{class_name} {

        public static void main(String[] argv) throws Exception {
            String fileName = "#{json_file}";

            Gson parser = new Gson();
            InputStream in = Files.newInputStream(Paths.get(fileName));
            String jsonString = readFully(new InputStreamReader(in));
            System.err.println("Processing JSON: " + jsonString);
            Type type = new TypeToken<Map<String, ObjectItem>>() { }.getType();
            try {
              // create json parser for type - hash of custom objects
              Map<String, ObjectItem> data = parser.fromJson(jsonString, type);
              // parse data to
              // ObjectItem dataItem = data.values().toArray()[0];
              ObjectItem dataItem = data.get(data.keySet().toArray()[0]);
              System.err.println("Processing Object: " + dataItem.getTitle());
            } catch (JsonSyntaxException e) {
              System.err.println("Exception (ignored) " + e.toString());
            }

        }
        public static String readFully(Reader reader) throws IOException {
          char[] arr = new char[0x200];
          StringBuffer stringBuffer = new StringBuffer();
          int numChars;

          while ((numChars = reader.read(arr, 0, arr.length)) > 0) {
              stringBuffer.append(arr, 0, numChars);
          }
          return stringBuffer.toString();
        }

        public static class ObjectItem {
          private String title;
          private Float price;
          private String url;
          private String id = null;

          public String getTitle() {
            return title;
          }

          public void setId(String data) {
            this.id = data;
          }

          public String getId() {
            return id;
          }

          public void setTitle(String data) {
            this.title = data;
          }

          public Float getPrice() {
            return price;
          }

          public void setPrice(Float data) {
            this.price = data;
          }

          public String getUrl() {
            return url;
          }

          public void setUrl(String data) {
            this.url = data;
          }

          private static final String staticInfo = "static info";

          public static String getStaticInfo() {
            return staticInfo;
          }

          public ObjectItem() {
            id = UUID.randomUUID().toString();
          }

        }
      }

    EOF
    before(:each) do
      $stderr.puts "Writing #{json_file}"
      file = File.open(json_file, 'w')
      file.puts json_data
      file.close
      $stderr.puts "Writing #{source_file}"
      file = File.open(source_file, 'w')
      file.puts source_data
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      export CLASSPATH=#{jars_cp}#{path_separator}.
      javac -cp #{jars_cp} '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      sleep 3
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      [
        'Processing JSON',
        'Processing Object',
      ].each do |line|
        its(:stderr) { should contain line }
      end
    end
  end
end
