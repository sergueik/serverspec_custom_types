require 'spec_helper'

require_relative '../type/command'
require 'yaml'
require 'json'
require 'csv'
require 'pp'

# use embedded XML class
# # alternarively use xmllint or xmlstarlet when installed
# https://www.xml.com/pub/a/2005/11/09/rexml-processing-xml-in-ruby.html
require 'rexml/document'
include REXML

context 'Jenkins jobs' do
  jobs_dir = '/opt/jenkins/jobs'
  config_dir = '/vagrant'
  context 'Confirm able to load config.xml' do
    [
      'good.xml',
      'bad.xml'
    ].each do |config|
      xml = "#{config_dir}/#{config}"
      describe command( "cat #{xml}") do
        its(:stdout_as_xml) { should respond_to :version }
      end
    end
  end
  # NOTE: malformed XML would abort the spec run altogether.
  context 'Detect malformed XML Document in Jenkins' do
    [
      'build1',
      'build2',
      'build3',
    ].each do |job|
      context "Able to load #{job} config" do
        file_path = "#{jobs_dir}/#{job}/config.xml"
        if File.exists?(file_path)
          begin
            file = File.new(file_path)
          rescue => ex
            $stderr.puts ex.to_s
            # throw ex
          end
          doc = Document.new(file)
          puts doc.version
	  # better yet set subject
          it { should match 'Able to load' }
        end
      end
    end
  end


   # jenkins multi job plugin offers UI for creating multi job phases and phase jobs
   # resulting in the following XML
   #  <builders>
   #    <com.tikal.jenkins.plugins.multijob.MultiJobBuilder>
   #      <phaseName>phase1</phaseName>
   #      <phaseJobs>
   #        <com.tikal.jenkins.plugins.multijob.PhaseJobsConfig>
   #          <jobName>test-naginator</jobName>
   #          <jobAlias/>
   #          <currParams>true</currParams>
   #          <aggregatedTestResults>false</aggregatedTestResults>
   #          <exposedSCM>false</exposedSCM>
   #          <disableJob>false</disableJob>
   #          <parsingRulesPath></parsingRulesPath>
   #          <maxRetries>1</maxRetries>
   #          <enableRetryStrategy>true</enableRetryStrategy>
   #          <enableCondition>false</enableCondition>
   #          <abortAllJob>true</abortAllJob>
   #          <condition/>
   #          <configs class="empty-list"/>
   #          <killPhaseOnJobResultCondition>FAILURE</killPhaseOnJobResultCondition>
   #          <buildOnlyIfSCMChanges>false</buildOnlyIfSCMChanges>
   #          <applyConditionOnlyIfNoSCMChanges>false</applyConditionOnlyIfNoSCMChanges>
   #  ...
   # it is frequently complement with a uno parameter plugin entry for selecting those jobs or groups of jobs
    # the test below exercises both

  context 'Confirm able to find reuired set of multijob job selections config.xml' do
    job_name = 'multijob'
    jobs_dir = '/opt/jenkins/jobs'
    xml = "#{jobs_dir}/#{job_name}/config.xml"
    context 'Phase Jobs' do
      java_class = 'com.tikal.jenkins.plugins.multijob.PhaseJobsConfig'
      describe command( <<-EOF
        CLASS='#{java_class}'
        xmllint --xpath "//${CLASS}/jobName" '#{xml}' | sed -e 's|\\(<jobName>\\)|\\1\\n|g' | sed -e 's|</*jobName>||g'
      EOF
      ) do
        [
          'name of job 1',
          'name of job 2'
        ].each do |job_name|
          its(:stdout) { should match Regexp.new(job_name, Regexp::IGNORECASE) }
        end
      end
    end
    context 'Uno Plugin Job selector' do
      select_name = 'Group'
      java_class = 'org.biouno.unochoice.ChoiceParameter'
      describe command( <<-EOF
        CLASS='#{java_class}'
        SELECT_NAME = '#{select_name}'
        xmllint --xpath "//${CLASS}/name[contains(text(),'${SELECT_NAME}')]/../script" '#{xml}'
      EOF
      ) do
        [
          'name of job 1',
          'name of job 2'
        ].each do |job_name|
          its(:stdout) { should match Regexp.new(job_name, Regexp::IGNORECASE) }
        end
      end
    end
  end
end

