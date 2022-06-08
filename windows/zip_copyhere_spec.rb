context 'Expanding zip using shell' do
  # TODO: before block
  # create an empty dir
  # cd %temp%
  # mkdir dummy
  # copy NUL dummy\file.txt
  # "c:\Program Files\7-Zip\7z.exe" a dummy.zip dummy
  # rd /s/q %temp%\dummy
  # $data = Get-Content -path 'c:\temp\dummy.zip' -Encoding Byte
  # $text = [System.Text.Encoding]::ASCII.GetString($data )
  # NOTE: the next command is incorrect, and will produce file of a zero size
  # Set-Content -Encoding Byte -Path 'c:\temp\dummy_new.zip' -Value ( $text -as [byte[]])
  # Set-Content -Encoding Byte -Path 'c:\temp\dummy_new.zip' -Value ( ([System.Text.Encoding]::ASCII.GetBytes($text)) -as [byte[]])
  # alternative is
  # [System.IO.File]::WriteAllBytes($path, $data)
  #
  # TODO: contruct parser of the messy output the errors are reported
  #< CLIXML
  # <Objs xmlns="http://schemas.microsoft.com/powershell/2004/04" Version="1.1.0.1">
  #   <Obj S="progress" RefId="0">
  #     <TN RefId="0">
  #       <T>System.Management.Automation.PSCustomObject</T>
  #       <T>System.Object</T>
  #     </TN>
  #     <MS>
  #       <I64 N="SourceId">1</I64>
  #       <PR N="Record">
  #         <AV>Preparing modules for first use.</AV>
  #         <AI>0</AI>
  #         <Nil/>
  #         <PI>-1</PI>
  #         <PC>-1</PC>
  #         <T>Completed</T>
  #         <SR>-1</SR>
  #         <SD> </SD>
  #       </PR>
  #     </MS>
  #   </Obj>
  #   <Obj S="information" RefId="1">
  #     <TN RefId="1">
  #       <T>System.Management.Automation.InformationRecord</T>
  #       <T>System.Object</T>
  #     </TN>
  #     <ToString>Downloading Latest Package from </ToString>
  #     <Props>
  #       <Obj N="MessageData" RefId="2">
  #         <TN RefId="2">
  #           <T>System.Management.Automation.HostInformationMessage</T>
  #           <T>System.Object</T>
  #         </TN>
  #         <ToString>Downloading Latest Package from </ToString>
  #         <Props>
  #           <S N="Message">Downloading Latest Package from </S>
  #           <B N="NoNewLine">false</B>
  #           <S N="ForegroundColor">DarkYellow</S>
  #           <S N="BackgroundColor">DarkMagenta</S>
  #         </Props>
  #       </Obj>
  #       <S N="Source">Write-Host</S>
  #       <DT N="TimeGenerated">2022-06-07T12:36:26.3664481-07:00</DT>
  #       <Obj N="Tags" RefId="3">
  #         <TN RefId="3">
  #           <T>System.Collections.Generic.List`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]</T>
  #           <T>System.Object</T>
  #         </TN>
  #         <LST>
  #           <S>PSHOST</S>
  #         </LST>
  #       </Obj>
  #       <S N="User">sergueik42\sergueik</S>
  #       <S N="Computer">sergueik42</S>
  #       <U32 N="ProcessId">4044</U32>
  #       <U32 N="NativeThreadId">2292</U32>
  #       <U32 N="ManagedThreadId">8</U32>
  #     </Props>
  #   </Obj>
  #   <S S="Error">You cannot call a method on a null-valued expression._x000D__x000A_</S>
  #   <S S="Error">At line:5 char:7_x000D__x000A_</S>
  #   <S S="Error">+       $zipItems = $shellApplication.NameSpace($path).Items()_x000D__x000A_</S>
  #   <S S="Error">+       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_x000D__x000A_</S>
  #   <S S="Error">    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException_x000D__x000A_</S>
  #   <S S="Error">    + FullyQualifiedErrorId : InvokeMethodOnNull_x000D__x000A_</S>
  #   <S S="Error"> _x000D__x000A_</S>
  #   <Obj S="progress" RefId="4">
  #     <TNRef RefId="0"/>
  #     <MS>
  #       <I64 N="SourceId">1</I64>
  #       <PR N="Record">
  #         <AV>Preparing modules for first use.</AV>
  #         <AI>0</AI>
  #         <Nil/>
  #         <PI>-1</PI>
  #         <PC>-1</PC>
  #         <T>Completed</T>
  #         <SR>-1</SR>
  #         <SD> </SD>
  #       </PR>
  #     </MS>
  #   </Obj>
  # </Objs>
  #< CLIXML

  # <Objs xmlns="http://schemas.microsoft.com/powershell/2004/04" Version="1.1.0.1">
  #   <Obj S="progress" RefId="0">
  #     <TN RefId="0">
  #       <T>System.Management.Automation.PSCustomObject</T>
  #       <T>System.Object</T>
  #     </TN>
  #     <MS>
  #       <I64 N="SourceId">1</I64>
  #       <PR N="Record">
  #         <AV>Preparing modules for first use.</AV>
  #         <AI>0</AI>
  #         <Nil/>
  #         <PI>-1</PI>
  #         <PC>-1</PC>
  #         <T>Completed</T>
  #         <SR>-1</SR>
  #         <SD> </SD>
  #       </PR>
  #     </MS>
  #   </Obj>
  #   <Obj S="progress" RefId="1">
  #     <TNRef RefId="0"/>
  #     <MS>
  #       <I64 N="SourceId">1</I64>
  #       <PR N="Record">
  #         <AV>Preparing modules for first use.</AV>
  #         <AI>0</AI>
  #         <Nil/>
  #         <PI>-1</PI>
  #         <PC>-1</PC>
  #         <T>Completed</T>
  #         <SR>-1</SR>
  #         <SD> </SD>
  #       </PR>
  #     </MS>
  #   </Obj>
  # </Objs>

  #< CLIXML
  # <Objs xmlns="http://schemas.microsoft.com/powershell/2004/04" Version="1.1.0.1">
  #   <S S="Error">At line:4 char:14_x000D__x000A_</S>
  #   <S S="Error">+     if ( -not  test-path -path $p ) {_x000D__x000A_</S>
  #   <S S="Error">+              ~_x000D__x000A_</S>
  #   <S S="Error">Missing expression after unary operator '-not'._x000D__x000A_</S>
  #   <S S="Error">At line:4 char:16_x000D__x000A_</S>
  #   <S S="Error">+     if ( -not  test-path -path $p ) {_x000D__x000A_</S>
  #   <S S="Error">+                ~~~~~~~~~_x000D__x000A_</S>
  #   <S S="Error">Unexpected token 'test-path' in expression or statement._x000D__x000A_</S>
  #   <S S="Error">At line:4 char:16_x000D__x000A_</S>
  #   <S S="Error">+     if ( -not  test-path -path $p ) {_x000D__x000A_</S>
  #   <S S="Error">+                ~~~~~~~~~_x000D__x000A_</S>
  #   <S S="Error">Missing closing ')' after expression in 'if' statement._x000D__x000A_</S>
  #   <S S="Error">At line:4 char:35_x000D__x000A_</S>
  #   <S S="Error">+     if ( -not  test-path -path $p ) {_x000D__x000A_</S>
  #   <S S="Error">+                                   ~_x000D__x000A_</S>
  #   <S S="Error">Unexpected token ')' in expression or statement._x000D__x000A_</S>
  #   <S S="Error">    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordEx _x000D__x000A_</S>
  #   <S S="Error">   ception_x000D__x000A_</S>
  #   <S S="Error">    + FullyQualifiedErrorId : MissingExpressionAfterOperator_x000D__x000A_</S>
  #   <S S="Error"> _x000D__x000A_</S>
  # </Objs>

  # xmllint -xpath "//*[local-name()='S'][@S='Error']/text()" error.xml | sed 's|_x000D_|\r|g; s|_x000A_|\n|g'
  # xmllint -xpath "//*[@S='Error']/text()" error.xml | sed 's|_x000D__x000A_|\n|g'
  describe command (<<-EOF
    $p = "${Env:Temp}\\dummy.zip"
    write-output "Expanding ${p}"
    # remove parenhesis around test path to trigger error
    if ( -not ( test-path -path $p )) {
      write-host ('Missing zip file {0}' -f $p)
      exit 1
    }
    # (new-object Net.WebClient).DownloadFile($r, $p)
    $s = new-object -com Shell.Application
    $o = $s.NameSpace($p).Items()
    write-output ('Found {0} items in the archive' -f $o.Count )
    $e = "${env:temp}\\dummy"
    if (!(test-path $e)) {
      [void](New-Item $e -type directory)
    }
    $s.NameSpace($e).CopyHere($o, 0x14)
    write-output 'Done'
    get-childitem -recurse -path $e| foreach-object { write-output ($_.FullName) }
    exit 0
  EOF
  ) do
    # NOTE: not 0
    its(:exit_status) { should eq 1 }
    its(:stdout) { should match /.*Expanding .*\\dummy.zip.*/ }
    its(:stdout) { should contain 'Found 1 items in the archive' }
    its(:stdout) { should match /.*dummy\\file.txt.*/ }
  end
end

