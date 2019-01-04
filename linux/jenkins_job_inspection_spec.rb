require 'spec_helper'
require 'pp'


# In some situations Jenkins is use  as a parallel Artifactory
# pull engine
context 'Jenkins Artifactory Job Command' do
  {
    'JENKINS_JOB_NAME' => 'ARTIFACTORY_BUILD_NAME'
  }.each do |jenkins_job_name,artifactory_build_name|
     jenkins_home = '/opt/jenkins'
     job_dir = "#{jenkins_home}/jobs/#{jenkins_job_name}"
     describe file (job_dir) do
       it {should be_directory }
     end
     describe file ("#{job_dir}/config.xml") do
       it {should be_file }
       # Evaluate that the <command> node of the job contains
       # REST call with shell escaped HTML-encoded quote symbol
       # \&quot;ARTIFACTORY_BUILD_NAME\&quot;
       its(:content) {should match Regexp.new('\\\\&quot;' + artifactory_build_name + '\\\\&quot;')}
     end
     # commont xpath locators are:
     # '//builders/hudson.tasks.Shell/command/text()' for the plain shell command step
     #
     # '//husdon.model.ChoiceParameterDefinition[description[text()="Critical Parameter"]]/choices'
     # for the hardcoded domain-specific critical choice options
     #    <husdon.model.ChoiceParameterDefinition>
     #      <name>parameter</name>
     #      <description>Critical Parameter</description>
     #      <choices class="java.util.Arrays$ArrayList">
     #        <a class="string-array">
     #          <string>FOO</string>
     #          <string>BAR</string>
     #        </a>
     #      </choices>
     #    </husdon.model.ChoiceParameterDefinition>
     # '//org.biouno.unochoice.ChoiceParameter[description[text()="Description of the Parameter"]]/script[@class="org.biouno.unochoice.model.Groovyscript"]/script/text()'
     # for some domain-specific critical job uno parameter that looks like
     #
     # <org.biouno.unochoice.ChoiceParameter plugin="uno-hoice@0.24">
     #   <name>ParameterName</name>
     #   <description>Description of the Parameter</description>
     #   <script class="org.biouno.unochoice.model.Groovyscript">
     #     <script>
     #       def res = 'PARAMETER'
     #     </script>
     #   </script>
     # </org.biouno.unochoice.ChoiceParameter>
     #

     describe command( <<-EOF
       xmllint xmllint --xpath '//script/text()' '#{job_dir}/config.xml'
     EOF
     ) do
        # Note: the HTML encoding will disappear after piping through xmllint
       its(:stdout) {should match Regexp.new('\\\\"' + artifactory_build_name + '\\\\"')}
     end
     describe file ("#{job_dir}/nextBuildNumber") do
       it { expect(subject).to be_file }
     end
  end
end
