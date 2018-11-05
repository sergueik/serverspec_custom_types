if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

# based on: https://groups.google.com/forum/#!topic/selenium-users/SKs7-5tOeiE
# NOTE: setting the CHROME_HEADLESS environment to 1, true has no effect
# nor requesting desiredCapabilities.browserName to "headlessChrome"
# https://github.com/bayandin/chromedriver
context 'Chromedriver session creation test' do

  webdriver_executable = 'chromedriver_win32.exe'
  webdriver_executable = 'chromedriver.exe'
  webdriver_dir = 'c:\\java\\selenium'
  hub_url = 'http://localhost:9515/session'

  # Using curl build from https://curl.haxx.se/download.html installed into 'c:\tools'
  # NOTE: cmd version does not really work well under Windows, better left commented
  # describe command(<<-EOF
  #   cmd --% /c start #{webdriver_path}\\#{webdriver_executable}
  #   cmd --% /c start curl.exe -# --header "Content-Type: application/json" --request POST --data "{\\"desiredCapabilities\\":{\\"browserName\\":\\"chrome\\"}}" #{hub_url}
  # EOF
  # ) do
  #   let(:path) {'C:\Program Files\Curl;c:\tools\curl-7.62.0-win32-mingw\bin'}
  #   its(:stdout) { should include('"status":0') }
  #   its(:exit_status) { should eq 0 }
  # end

  describe command(<<-EOF
    $hub_url = '#{hub_url}'
    $webdriver_filepath = "#{webdriver_dir}\\#{webdriver_executable}"
    unblock-file $webdriver_filepath
    # https://stackoverflow.com/questions/5377423/hide-console-window-from-process-start-c-sharp
    $Process = new-object System.Diagnostics.Process
    [System.Diagnostics.ProcessStartInfo]$startInfo = new-object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $webdriver_filepath;
    $startInfo.Arguments = @()
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $process.StartInfo = $startInfo
    $status = $process.start()
    if (-not $status){
      write-error 'Failed to communicate with the chromedriver'
      exit 1
    }
    $id = $process.Id
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
    # TODO: pass option to run headlessly
    write-output (new-object System.IO.StreamReader($response) ).ReadToEnd()
    start-sleep -millisecond 5000
    try {
      stop-process -id $id -ErrorAction stop
      write-output "Successfully killed the process with ID: ${id}"
    } catch {
      # NOTE: if a failed run leaves behind a runing chromedriver process(es) subsequent runs will fail also
      write-error "Failed to kill the chromedriver process with ID: ${id}"
      exit 1
    }
  EOF
  ) do
    its(:stdout) { should match /"status":0/ }
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
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty}
    describe process('chrome.exe') do
      it { should be_running }
    end
  end
  describe command(<<-EOF
    $hub_url = '#{hub_url}'
    $webdriver_filepath = '#{webdriver_dir}\\#{webdriver_executable}'
    $process = start-process -windowstyle hidden $webdriver_filepath -passthru
    write-output "Chromedriver Process Id is ${process.Id}"
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
    $obj = convertFrom-json -InputObject ((new-object System.IO.StreamReader($response) ).ReadToEnd())
    write-output ('"status":{0}' -f $obj.'status')
    if ($obj.'status' -ne 0){
      write-error 'Failed to launch chrome via the chromedriver'
    }
    try {
      stop-process -id $id -ErrorAction stop
      write-output "Successfully killed the process with ID: ${id}"
    } catch {
      write-output 'Failed to kill the chromedriver process'
    }
    # for CDP see https://medium.com/@dschnr/using-headless-chrome-as-an-automated-screenshot-tool-4b07dffba79a
    try {
      # https://bugs.chromium.org/p/chromedriver/issues/detail?id=2311&q=&colspec=ID%20Status%20Pri%20Owner%20Summary
      # Chromedriver leaves forked Chrome instances hanging with large CPU load
      stop-process (get-process -name 'chrome') -ErrorAction stop
      write-output 'Successfully killed the chrome browser processes'
    } catch {
      write-error 'Failed to kill the chrome browser process'
    }
  EOF
  ) do
    its(:stdout) { should include '"status":0' }
    its(:stdout) { should include 'Successfully killed the chrome browser processes' }
    its(:stderr) { should be_empty}
    its(:exit_status) { should eq 0 }
  end
end
