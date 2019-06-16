require_relative '../windows_spec_helper'
$DEBUG = false
# based on http://forum.oszone.net/thread-340860.html
context 'Partially debugged Powershell one-liner' do
  class Integer
    def in?(arr)
      status = false
      if $DEBUG
        $stderr.puts self
      end  
      arr.each do |elem|
        if self == elem
          status = true
        end
      end
      status
    end
  end
  # silently applying conversion from enum 
  # SERVICE_STOPPED - 0x00000001
  # SERVICE_START_PENDING - 0x00000002
  # SERVICE_STOP_PENDING - 0x00000003
  # SERVICE_RUNNING - 0x00000004
  # SERVICE_CONTINUE_PENDING - 0x00000005
  # SERVICE_PAUSE_PENDING - 0x00000006
  # SERVICE_PAUSED - 0x00000007
  # and bool 
  # to int
  {
    'Winmgmt'  => 'service is running',
    'wuauserv' => 'service is stopped',
    'zzz'      => 'service is running', # status will be 1
  }.each do |servicename,status|
    describe command("$service_name = '#{servicename}'; .({write-output 'service is running'},{write-output 'service is stopped'})[(get-service $service_name ).Status -eq 1]") do
      its(:stdout) { should match status }
      its(:exit_status) { should be_in( [0,1] ) }
    end
    describe command("$service_name = '#{servicename}'; .({write-output 'service is running'},{write-output 'service is stopped'})[[int]([int]((get-service -name $service_name ).Status) -eq 1)]") do
      its(:stdout) { should match status }
      its(:exit_status) { should be_in( [0,1] ) }
    end
    describe command("$service_name = '#{servicename}'; .({if( !$$ ){ throw };'service is running'},{'service is stopped'})[($$ = gsv $service -ea 0).Status -eq 1]") do
      its(:stdout) { should match status }
      its(:exit_status) { should be_in( [0,1] ) }
    end
  end
end
