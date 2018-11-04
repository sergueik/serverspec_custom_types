if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end


# based on: https://groups.google.com/forum/#!topic/selenium-users/SKs7-5tOeiE
# NOTE: does not really work well under Windows
context 'Chromedriver session creation test' do

  driver_executable = 'chromedriver_win32.exe'
  driver_executable = 'chromedriver.exe'

  describe command(<<-EOF
     cmd --% /c start c:\\java\\selenium\\#{driver_executable}
     cmd --% /c start curl.exe -# --header "Content-Type: application/json" --request POST --data "{\\"desiredCapabilities\\":{\\"browserName\\":\\"chrome\\"}}" http://localhost:9515/session "{\\"sessionId\\":\\"644b14c3c65a2f0970413ca15fd70801\\",\\"status\\":0,\\"value\\":{\\"acceptInsecureCerts\\":false,\\"acceptSslCerts\\":false,\\"applicationCacheEnabled\\":false,\\"browserConnectionEnabled\\":false,\\"browserName\\":\\"chrome\\",\\"chrome\\":{\\"chromedriverVersion\\":\\"2.42.591088 (7b2b2dca23cca0862f674758c9a3933e685c27d5)\\",\\"userDataDir\\":\\"C:\\\\Users\\\\Serguei\\\\AppData\\\\Local\\\\Temp\\\\scoped_dir32_19601\\"},\\"cssSelectorsEnabled\\":true,\\"databaseEnabled\\":false,\\"goog:chromeOptions\\":{\\"debuggerAddress\\":\\"localhost:59409\\"},\\"handlesAlerts\\":true,\\"hasTouchScreen\\":false,\\"javascriptEnabled\\":true,\\"locationContextEnabled\\":true,\\"mobileEmulationEnabled\\":false,\\"nativeEvents\\":true,\\"networkConnectionEnabled\\":false,\\"pageLoadStrategy\\":\\"normal\\",\\"platform\\":\\"Windows NT\\",\\"rotatable\\":false,\\"setWindowRect\\":true,\\"takesHeapSnapshot\\":true,\\"takesScreenshot\\":true,\\"unexpectedAlertBehaviour\\":\\"\\",\\"version\\":\\"70.0.3538.77\\",\\"webStorageEnabled\\":true}}"
  EOF
  ) do
  let(:path) {'C:\Program Files\Curl;c:\tools\curl-7.62.0-win32-mingw\bin'}
    # WOULD return response {"sessionId":"2721a58c9c96ece4360ac5693c29b2a7","status":0,"value":{"acceptInsecureCerts":false,"acceptSslCerts":false,"applicationCacheEnabled":false,"browserConnectionEnabled":false,"browserName":"chrome","chrome":{"chromedriverVersion":"2.36.540470 (e522d04694c7ebea4ba8821272dbef4f9b818c91)","userDataDir":"C:\\Users\\Serguei\\AppData\\Local\\Temp\\scoped_dir6248_24713"},"cssSelectorsEnabled":true,"databaseEnabled":false,"handlesAlerts":true,"hasTouchScreen":false,"javascriptEnabled":true,"locationContextEnabled":true,"mobileEmulationEnabled":false,"nativeEvents":true,"networkConnectionEnabled":false,"pageLoadStrategy":"normal","platform":"Windows NT","rotatable":false,"setWindowRect":true,"takesHeapSnapshot":true,"takesScreenshot":true,"unexpectedAlertBehaviour":"","version":"70.0.3538.67","webStorageEnabled":true}}

    its(:stdout) { should include('"status":0') }
    its(:exit_status) { should eq 0 }
  end
end

