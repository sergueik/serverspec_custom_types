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
     describe file ("#{job_dir}/nextBuildNumber") do
       it { expect(subject).to be_file }
     end
  end
end