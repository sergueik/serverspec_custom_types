if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end


# based on: https://groups.google.com/forum/#!topic/selenium-users/SKs7-5tOeiE
# NOTE: does not really work well under Windows
context 'Chromedriver session creation test' do

  webdriver_executable = 'chromedriver_win32.exe'
  webdriver_executable = 'chromedriver.exe'
  webdriver_path = 'c:\\java\\selenium'
  hub_url = 'http://localhost:9515/session'

  describe command(<<-EOF
    cmd --% /c start #{webdriver_path}\\#{webdriver_executable}
    cmd --% /c start curl.exe -# --header "Content-Type: application/json" --request POST --data "{\\"desiredCapabilities\\":{\\"browserName\\":\\"chrome\\"}}" #{hub_url}
  EOF
  ) do
  # Using curl build from https://curl.haxx.se/download.html installed into 'c:\tools'
  let(:path) {'C:\Program Files\Curl;c:\tools\curl-7.62.0-win32-mingw\bin'}
    # Would respond with the following JSON
    #  {
    #    "sessionId": "2721a58c9c96ece4360ac5693c29b2a7",
    #    "status": 0,
    #    "value": {
    #      "acceptInsecureCerts": false,
    #      "acceptSslCerts": false,
    #      "applicationCacheEnabled": false,
    #      "browserConnectionEnabled": false,
    #      "browserName": "chrome",
    #      "chrome": {
    #        "chromedriverVersion": "2.36.540470 (e522d04694c7ebea4ba8821272dbef4f9b818c91)",
    #        "userDataDir": "C:\\Users\\Serguei\\AppData\\Local\\Temp\\scoped_dir6248_24713"
    #      },
    #      "cssSelectorsEnabled": true,
    #      "databaseEnabled": false,
    #      "handlesAlerts": true,
    #      "hasTouchScreen": false,
    #      "javascriptEnabled": true,
    #      "locationContextEnabled": true,
    #      "mobileEmulationEnabled": false,
    #      "nativeEvents": true,
    #      "networkConnectionEnabled": false,
    #      "pageLoadStrategy": "normal",
    #      "platform": "Windows NT",
    #      "rotatable": false,
    #      "setWindowRect": true,
    #      "takesHeapSnapshot": true,
    #      "takesScreenshot": true,
    #      "unexpectedAlertBehaviour": "",
    #      "version": "70.0.3538.67",
    #      "webStorageEnabled": true
    #    }
    #  }
    its(:stdout) { should include('"status":0') }
    its(:exit_status) { should eq 0 }
  end

  describe command(<<-EOF
    $hub_url = '#{hub_url}'
    start-process -WindowStyle hidden #{webdriver_path}\\#{webdriver_executable}
    $body = [byte[]][char[]]'{"desiredCapabilities":{"browserName":"chrome"}}'
    $request = [System.Net.HttpWebRequest]::CreateHttp($hub_url)
    $request.Method = 'POST'
    $request.Timeout = 10000
    $request.ContentType = 'application/json'
    $stream = $request.GetRequestStream()
    $stream.Write($body, 0, $body.Length)
    $stream.Flush()
    $stream.Close()
    $response = $request.GetResponse().GetResponseStream()
    # opens the browser
    write-output (new-object System.IO.StreamReader($response) ).ReadToEnd()
  EOF
  ) do
    its(:stdout) { should include('"status":0') }
    its(:exit_status) { should eq 0 }
  end
end
