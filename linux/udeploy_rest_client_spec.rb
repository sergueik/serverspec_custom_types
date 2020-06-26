# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'Udeploy Agent Client tests' do

  context 'xxx' do
    jars  = %w|
      uc-uDeployRestClient-1.0-SNAPSHOT.jar
      commons-codec-1.5.jar
      uc-jettison-1.0-SNAPSHOT.jar
    |
    jar_path = '/tmp'
    path_separator = ':'
    jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)

    class_name = 'BasicAgentClientTest'
    source_file = "#{class_name}.java"

    source = <<-EOF

      import java.io.IOException;
      import java.net.URI;
      import java.net.URISyntaxException;

      import org.apache.commons.codec.EncoderException;
      import com.urbancode.ud.client.AgentClient;
      import org.codehaus.jettison.json.JSONException;
      import org.codehaus.jettison.json.JSONObject;

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

        public static void main(String[] args) throws URISyntaxException, IOException, JSONException {
          commandLineParser = new CommandLineParser();
          commandLineParser.saveFlagValue("user");
          commandLineParser.saveFlagValue("password");
          commandLineParser.saveFlagValue("agent");

          commandLineParser.parse(args);

          if (commandLineParser.hasFlag("debug")) {
            debug = true;
          }
          String user = commandLineParser.getFlagValue("user");
          if (user == null) {
            System.err.println("Missing required argument: user - assuming default");
            user = "admin";
            // return;
          }
          String password = commandLineParser.getFlagValue("password");
          if (password == null) {
            System.err.println("Missing required argument: password - assuming default");
            password = "admin";
            // return;
          }

          String agent = commandLineParser.getFlagValue("agent");
          if (agent == null) {
            System.err.println("Missing required argument: agent");
            return;
          }
          client = new AgentClient(new URI("https://localhost:8443"), user, password);
          if (client == null) {
            throw new RuntimeException(String.format("failed to connect as %s / password %s", user, password));
          } else {
            data = client.getAgent(agent);
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
              // NOTE: will crash echo '${script_file}'
                String name = args[n].replaceFirst("-", "");
                String value = null;
                // remove the dash
                if (debug) {
                  System.err.println("Examine: " + name);
                }
                if (flagsWithValues.contains(name) && n < args.length - 1) {
                  value = args[++n];
                  if (debug) {
                    System.err.println("Collect value for: " + name + " = " + value);
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
          public Map<String, String> extractExtraArgs(String argument) throws IllegalArgumentException {

            final Map<String, String> extraArgData = new HashMap<>();
            argument = argument.trim().substring(1, argument.length() - 1);
            if (argument.indexOf("{") > -1 || argument.indexOf("}") > -1) {
              if (debug) {
                System.err.println("Found invalid nested data");
              }
              throw new IllegalArgumentException("Nested JSON athuments not supprted");
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
      javac -cp uc-uDeployRestClient-1.0-SNAPSHOT.jar:commons-codec-1.5.jar:uc-jettison-1.0-SNAPSHOT.jar '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}' -agent dummy -user admin -password admin
    EOF
    ) do
      its(:exit_status) { should eq 1 }
      its(:stdout) { should be_empty }
      its(:stderr) { should contain 'No agent with id/name dummy' }
    end
  end
end
