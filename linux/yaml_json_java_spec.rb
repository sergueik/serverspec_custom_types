if File.exists?( 'spec/windows_spec_helper.rb')
"# Copyright (c) Serguei Kouzmine"
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'SAX HTML tests' do
  catalina_home = '/opt/tomcat'
  path_separator = ':'
  # gson is one of de facto ord-time standard JSON processors
  # is likely present in tomcat lib directory for apps deployed in tomcat container
  # or in or some flexible 'lib' under the app directory for a standalone springboot app
  app_name = '<application>'
  jar_path = "#{catalina_home}/webapps/#{app_name}/WEB-INF/lib/"
  app_base_path = "/opt/#{app_name}/snandalone/lib"
  jar_path = "#{app_base_path}/lib"
  jar_path = '/tmp'
  jar_versions = {
    'gson'      => '2.7',
    'snakeyaml' => '1.13'
  }
  jar_versions = {
    'gson'      => '2.8.5',
    'snakeyaml' => '1.25'
  }

  jar_search_string = '(' + jar_versions.keys.join('|') + ')'
  jars = []
  jar_versions.each do |artifactid,version|
    jars.push artifactid + '-' + version + '.' + 'jar'
  end

  # TODO: below is incorrect
  # jars = jar_versions.each { |artifactid,version|  artifactid + '-' + version + '.'  + 'jar' }

  jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)
  tmp_path = '/tmp'
  yaml_file = "#{tmp_path}/group.yaml"

  # NOTE: indent sensitive
  yaml_data = <<-EOF
---
  - artist:
    id: 001
    name: john
    plays: guitar
  - artist:
    id: 002
    name: ringo
    plays: drums
  - artist:
    id: 003
    name: paul
    plays: vocals
  - artist:
    id: 004
    name: george
    plays: guitar
  EOF
  class_name = 'StronglyTypedYAMLJSONReport'
  report = 'report.json'
  source_file = "#{tmp_path}/#{class_name}.java"
  source_data = <<-EOF

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.lang.reflect.Type;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

import java.util.UUID;

import org.yaml.snakeyaml.Yaml;

import com.google.gson.FieldNamingStrategy;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializationContext;
import com.google.gson.JsonSerializer;

public class #{class_name} {

	public static void main(String[] argv) throws Exception {
      String fileName = "#{yaml_file}";

      // https://www.programcreek.com/java-api-examples/index.php?api=com.google.gson.JsonSerializer
      Gson gson = new GsonBuilder()
          .registerTypeAdapter(Artist.class, new JsonSerializer<Artist>() {
            @Override
            public JsonElement serialize(final Artist data, final Type type,
                final JsonSerializationContext context) {
              JsonObject result = new JsonObject();
              int id = data.getId();
              if (id != 0) {
                result.add("id", new JsonPrimitive(id));
              }

              @SuppressWarnings("unused")
              String name = data.getName();
              // example of filtering what to (not) serialize
              // real name will be lacking
              result.add("name", new JsonPrimitive("unknown"));

              String plays = data.getPlays();
              if (plays != null && !plays.isEmpty()) {
                result.add("plays", new JsonPrimitive(plays));
              }
              return result;
            }
          }).create();
    		List<JsonElement> group = new ArrayList<>();

		try {
			FileOutputStream fos = new FileOutputStream("#{report}");
			OutputStreamWriter writer = new OutputStreamWriter(fos, "UTF-8");

			InputStream in = Files.newInputStream(Paths.get(fileName));

			@SuppressWarnings("unchecked")
			ArrayList<LinkedHashMap<Object, Object>> members = (ArrayList<LinkedHashMap<Object, Object>>) new Yaml()
					.load(in);
			System.err.println(
					String.format("Loaded %d members of the group", members.size()));
			for (LinkedHashMap<Object, Object> row : members) {
				System.err.println(String.format("Loaded %d propeties of the artist",
						row.keySet().size()));
          Artist artist = new Artist((int) row.get("id"),
              (String) row.get("name"), (String) row.get("plays"));
              String artistJsonStr = gson.toJson(artist);
          JsonElement artistJson = gson.toJsonTree(artist, Artist.class);
          System.err.println(
              "JSON serialization with gson:\\n" + artistJsonStr);
				group.add(artistJson);
			}
      System.err.println(gson.toJson(group));
      writer.write(gson.toJson(group));
      writer.flush();
			writer.close();
		} catch (IOException e) {
			System.err.println("Excption (ignored) " + e.toString());
		}

	}

	public static class Artist {

		private String name;
		private String plays;
		private static String staticInfo;
		private int id;

		@SuppressWarnings("unused")
		public String getName() {
			return name;
		}

		@SuppressWarnings("unused")
		public static String getStaticInfo() {
			return staticInfo;
		}

		@SuppressWarnings("unused")
		public void setName(String data) {
			name = data;
		}

		@SuppressWarnings("unused")
		public String getPlays() {
			return plays;
		}

		@SuppressWarnings("unused")
		public void setPlays(String data) {
			plays = data;
		}

		@SuppressWarnings("unused")
		public int getId() {
			return id;
		}

		@SuppressWarnings("unused")
		public void setId(int data) {
			id = data;
		}

		@SuppressWarnings("unused")
		public Artist() {
			staticInfo = UUID.randomUUID().toString();
		}

		public Artist(int id, String name, String plays) {
			super();
			this.name = name;
			this.id = id;
			this.plays = plays;
		}

	}
}

  EOF
  before(:each) do
    $stderr.puts "Writing #{yaml_file}"
    file = File.open(yaml_file, 'w')
    file.puts yaml_data
    file.close
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    rm -f "#{report}"
    export CLASSPATH=#{jars_cp}#{path_separator}.
    javac -cp #{jars_cp} '#{source_file}'
    java -cp #{jars_cp}#{path_separator}. '#{class_name}'
    sleep 3
    1>/dev/null 2>/dev/null popd
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    [
      'Loaded 4 members of the group',
      'Loaded 4 propeties of the artist',
    ].each do |line|
      its(:stderr) { should contain line }
    end
    describe file "#{tmp_path}/#{report}" do
      it { should be_file }
    end
    describe command("jq '.[].id' < '#{tmp_path}/#{report}'") do
      its(:exit_status) { should eq 0 }
      [1,2,3,4].each do |id|
        its(:stdout) {  should contain id }
      end
    end
  end
end

