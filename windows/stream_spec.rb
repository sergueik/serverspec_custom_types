require_relative '../windows_spec_helper'

# based on: https://www.cyberforum.ru/powershell/thread2632563.html

# see also: http://forum.oszone.net/thread-341800.html
# see also: http://hex.pp.ua/ntfs-stream-explorer.php (in Russian)
# http://hex.pp.ua/RmMetadata.php
# for about the implementation of file streams see also: 
# http://hex.pp.ua/extended-attributes.php (in Russian)
# see also: https://blogs.msmvps.com/bsonnino/2016/11/24/alternate-data-streams-in-c/
# (not pure: relies on 'Trinet.Core.IO.Ntfs' assembly)
# see also: https://stackoverflow.com/questions/604960/ntfs-alternate-data-streams-net
# for further discussions of the pinvoke'able "kernel32.dll" NTFS methods
context 'File Streams' do
  custom_data = 'custom data' 
  stream_name = 'Stream.Data'
  file_name = 'stream_test.txt'
  describe command(<<-EOF
    $file_name = '#{file_name}'
    $file_path = "${env:TEMP}\\${file_name}"
    set-content -path $file_path -value 'stream test'
    
    $stream_name = '#{stream_name}'
    $data = '#{custom_data}'
    set-content -path $file_path -stream $stream_name -value ("[{0}]`n{1}" -f $stream_name, $data)
    
    get-item -path $file_path -stream $stream_name -erroraction stop |format-list
    get-content -path $file_path -Stream $stream_name -erroraction stop
    
    remove-item -path $file_path
  EOF
  ) do
    its(:stdout) { should match stream_name }
    its(:stdout) { should match /\[#{stream_name}\]/ }
    its(:stdout) { should match /#{file_name}:#{stream_name}/ }
    its(:stderr) { should be_empty }
    # NOTE: collapsing "should" will make rake think there is just one expectation
  end
end
