# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'Udeploy Agent Client tests' do

  context 'get resource children' do
    jars  = %w|
      uc-uDeployRestClient-1.0-SNAPSHOT.jar
      commons-codec-1.5.jar
      uc-jettison-1.0-SNAPSHOT.jar
    |
    jar_path = '/tmp'
    path_separator = ':'
    jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)
    java_home = '/opt/java'
    password = 'admin'
    user = 'admin'
    server = 'https://localhost:8443'
    env = '172ecdb3-50a2-e489-6b50-1399b396b6fb' 
    class_name = 'BasicAgentClientTest'
    source_file = "#{class_name}.java"

    source = <<-EOF

      import java.io.IOException;
      import java.net.URI;
      import java.net.URISyntaxException;

      import org.apache.commons.codec.EncoderException;
      import com.urbancode.ud.client.AgentClient;
      import com.urbancode.ud.client.ResourceClient;

      import org.codehaus.jettison.json.JSONException;
      import org.codehaus.jettison.json.JSONObject;
      import org.codehaus.jettison.json.JSONArray;

      import java.util.ArrayList;
      import java.util.HashMap;
      import java.util.HashSet;
      import java.util.List;
      import java.util.Map;
      import java.util.Set;

      public class #{class_name} {
        private static boolean debug = false;
        private static CommandLineParser commandLineParser;

        private static AgentClient client;
        private static JSONObject data;

        public static void main(String[] args)
            throws URISyntaxException, IOException, JSONException {
          commandLineParser = new CommandLineParser();
          commandLineParser.flagsWithValues.add("user");
          commandLineParser.flagsWithValues.add("password");
          commandLineParser.saveFlagValue("server");
          commandLineParser.saveFlagValue("env");

          commandLineParser.parse(args);

          if (commandLineParser.flags.containsKey("debug")) {
            debug = true;
          }
          // static inner allows accessing private members from enclosing class
          // directly
          String user = commandLineParser.flags.get("user");
          if (user == null) {
            user = "admin";
            System.err.println("Missing argument: user - using default");
          }
          String password = commandLineParser.flags.get("password");
          if (password == null) {
            password = "admin";
            System.err.println("Missing argument: password - using default");
          }
          String server = commandLineParser.getFlagValue("server");
          if (server == null) {
            server = "https://localhost:8443";
            System.err.println("Missing argument: server - using default");
          }
          // TODO: get env id legitimately
          String env = commandLineParser.getFlagValue("env");
          if (env == null) {
            // env = "172ecdb3-50a2-e489-6b50-1399b396b6fb";
            System.err.println("Missing required argument: env");
            return;
          }

          // explore resource hierarchy
          ResourceClient resourceClient = new ResourceClient(new URI(server), user,
              password);
          if (resourceClient == null) {
            throw new RuntimeException(String
                .format("failed to connect as %s / password %s", user, password));
          }
          JSONArray jsonArray = resourceClient.getResourceChildren(env);
          for (int index = 0; index != jsonArray.length(); index++) {
            JSONObject childObject = jsonArray.getJSONObject(index);
            System.out.println("  - " + childObject.getString("name"));
          }
          if (debug) {
            System.out.println("{\"" + env + "\": " + jsonArray + " }");
          }
          for (int index = 0; index != jsonArray.length(); index++) {
            JSONObject childObject = jsonArray.getJSONObject(index);
            String id1 = childObject.getString("id");

            JSONArray ce1 = resourceClient.getResourceChildren(id1);
            // String id1 = "172ecdb9-54f7-c269-9cca-fd8bd9ee6341";
            if (debug) {
              System.out.println("{\"" + id1 + "\": " + ce1 + " }");
            }
            for (int index1 = 0; index1 != ce1.length(); index1++) {
              JSONObject childObject1 = ce1.getJSONObject(index1);
              System.out.println("    - " + childObject1.getString("name"));
            }
          }
        }

        private static class CommandLineParser {

          private boolean debug = false;

          public boolean isDebug() {
            return debug;
          }

          public void setDebug(boolean debug) {
            this.debug = debug;
          }

          // pass-through
          private String[] arguments = null;

          public String[] getArguments() {
            return arguments;
          }

          private Map<String, String> flags = new HashMap<>();

          //
          // the flag values that are expected to be followed with a value
          // that allows the application to process the flag.
          //
          private Set<String> flagsWithValues = new HashSet<>();

          public Set<String> getFlags() {
            Set<String> result = flags.keySet();
            return result;
          }

          public String getFlagValue(String flagName) {
            return flags.get(flagName);
          }

          public int getNumberOfArguments() {
            return arguments.length;
          }

          public int getNumberOfFlags() {
            return flags.size();
          }

          public boolean hasFlag(String flagName) {
            return flags.containsKey(flagName);
          }

          // contains no constructor nor logic to discover unknown flags
          public void parse(String[] args) {
            List<String> regularArgs = new ArrayList<>();

            for (int n = 0; n < args.length; ++n) {
              if (args[n].charAt(0) == '-') {
                String name = args[n].replaceFirst("-", "");
                String value = null;
                // remove the dash
                if (debug) {
                  System.err.println("Examine: " + name);
                }
                if (flagsWithValues.contains(name) && n < args.length - 1) {
                  String data = args[++n];
                  // https://www.baeldung.com/java-case-insensitive-string-matching
                  value = data.matches("(?i)^env:[a-z_0-9]+")
                      ? System.getenv(data.replaceFirst("(?i)^env:", "")) : data;

                  if (debug) {
                    if (data.matches("(?i)^env:[a-z_0-9]+")) {
                      System.err
                          .println("Evaluate value for: " + name + " = " + value);

                    } else {
                      System.err
                          .println("Collect value for: " + name + " = " + value);
                    }
                  }
                } else {
                  if (debug) {
                    System.err.println("Ignore the value for " + name);
                  }
                }
                flags.put(name, value);
              }

              else
                regularArgs.add(args[n]);
            }

            arguments = regularArgs.toArray(new String[regularArgs.size()]);
          }

          public void saveFlagValue(String flagName) {
            flagsWithValues.add(flagName);
          }

          private static final String keyValueSeparator = ":";
          private static final String entrySeparator = ",";

          // Example data:
          // -argument "{count:0, type:navigate, size:100, flag:true}"
          // NOTE: not using org.json to reduce size
          public Map<String, String> extractExtraArgs(String argument)
              throws IllegalArgumentException {

            final Map<String, String> extraArgData = new HashMap<>();
            argument = argument.trim().substring(1, argument.length() - 1);
            if (argument.indexOf("{") > -1 || argument.indexOf("}") > -1) {
              if (debug) {
                System.err.println("Found invalid nested data");
              }
              throw new IllegalArgumentException(
                  "Nested JSON athuments not supprted");
            }
            final String[] pairs = argument.split(entrySeparator);

            for (String pair : pairs) {
              String[] values = pair.split(keyValueSeparator);

              if (debug) {
                System.err.println("Collecting: " + pair);
              }
              extraArgData.put(values[0].trim(), values[1].trim());
            }
            return extraArgData;
          }

        }
      }
    EOF
    before(:each) do
      $stderr.puts "Writing '/tmp/#{source_file}'"
      file = File.open("/tmp/#{source_file}", 'w')
      file.puts source
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null cd /tmp
      export SECRET=#{password}
      javac -cp #{jars_cp} '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}' -server #{server} -user #{user} -password env:SECRET -env #{env}
    EOF
    ) do
      let(:path) { "/bin:/usr/bin:/sbin:#{java_home}/bin" }
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
    end
  end
end
