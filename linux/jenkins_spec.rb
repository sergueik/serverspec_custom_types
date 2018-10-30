require 'spec_helper'
require 'pp'
context 'Jenkins' do

  begin
    require 'xmlsimple'
    test_xml = true
  rescue LoadError => e
    test_xml = false
  end

  if ['redhat', 'debian', 'ubuntu'].include?(os[:family])
    # on Linux
    jenkins_home = '/var/lib/jenkins'
  else
    # on Windows
    jenkins_home = 'C:/java/jenkins.2.321/master/'
  end

  # will fail
  context 'Bad Example to skip XML test', :if => !test_xml do
    $stderr.puts 'Skipped XML test: '
    $stderr.puts "test_xml = '#{test_xml}'"
  end


  context 'Plugins' do
    jenkins_home = '/var/lib/jenkins'
    {
      'subversion'=> '1.54',
      'windows-slaves'=> nil,
    }.each do |plugin, version|
      describe file("#{jenkins_home}/plugins/#{plugin}/META-INF") do
        it { should be_directory }
      end
      if ! version.nil?
        describe file("#{jenkins_home}/plugins/#{plugin}/META-INF/MANIFEST.MF") do
          it { should be_file }
          it { should contain( 'Plugin-Version: ' + version ) }
        end
      end
      [
        'pom.properties',
        'pom.xml',
      ].each do |filename|
        # path will vary wth package - need to glob
        describe file("#{jenkins_home}/plugins/#{plugin}/META-INF/maven/org.jenkins-ci.plugins/#{plugin}/#{filename}") do
          it { should be_file }
        end
      end
    end

    context 'Jobs' do
      context 'Directory' do
        [
          'JOB NAME',
        ].each do |job|
          describe file("#{jenkins_home}/jobs/#{job}") do
            it { should be_directory }
          end
          describe file("#{jenkins_home}/jobs/#{job}/config.xml") do
            it { should be_file }
          end
          describe file("#{jenkins_home}/jobs/#{job}/nextBuildNumber") do
            it { should be_file }
          end
        end
      end

      context 'config.xml' do
        if test_xml
          {
            'pipeline' =>  [
              'plugin',
              'description',
              'keepDependencies',
              'properties',
              'definition',
              'triggers'
            ],
            'freestyle' => [
              'description',
              'keepDependencies',
              'properties',
              'scm',
              'canRoam',
              'disabled',
              'blockBuildWhenDownstreamBuilding',
              'blockBuildWhenUpstreamBuilding',
              'triggers',
              'concurrentBuild',
              'builders',
              'publishers',
              'buildWrappers'
            ],
          }.each do |type, keys|
            job_name = "test_#{type}"
            begin
              config = XmlSimple.xml_in("#{jenkins_home}/jobs/#{job_name}/config.xml")
              pp config.keys
              pp config['plugin'] # {'plugin'=>'workflow-job@2.9',
            rescue ArgumentError => e
            end
          end

          # NOTE: the root node could e.g. be com.tikal.jenkins.plugins.multijob.MultiJobProject
          # if https://wiki.jenkins.io/display/JENKINS/Multijob+Plugin is used
          describe command(<<-EOF
            xmllint -xpath "name(//*[contains(local-name(),'Project') or contains(local-name(), 'project') or contains(local-name(), 'flow-definition') ])" "#{jenkins_home}/jobs/#{job_name}/config.xml"
          EOF
          ) do
            let(:path) { '/bin:/usr/bin:/usr/local/bin'}
            its(:stdout) { should match /(:?project|flow)/ }
          end
        else
          puts 'Skipped using xmlsimple gem for XML test'
        end
      end
    end
  end
# NOTE: NoMethodError:  undefined method ` ' for RSpec::ExampleGroups::Jenkins::Plugins::Jobs::JobRetryPlugin:Class
  context 'Job retry plugin' do
    jenkins_home = '/var/lib/jenkins'
    job_name = 'sample_job'
    jenkins_class_name = 'Naginator'
    # some Jenkins nodes list the package / class name as the name of the node, others set it as an attribute
    describe command(<<-EOF
      JENKINS_HOME='#{jenkins_home}'
      JENKINS_CLASS_NAME='#{jenkins_class_name}'
      JOB_NAME='#{job_name}'
      xmllint -xpath "name(//publishers/*[contains(local-name(),'${JENKINS_CLASS_NAME}') ])" "#{jenkins_home}/jobs/#{job_name}/config.xml"
    EOF
    ) do

      let(:path) { '/bin:/usr/bin:/usr/local/bin' }
      # its(:stdout) { should match /(:?#{jenkins_class_name})/ }
      # its(:stderr) { should be_empty }
      # its(:exit_status) {should eq 0 }
    end
  end
end

