require_relative  '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Executable header Test' do
  filepath = 'c:/Ruby23/bin/ruby.exe'

  # origin: https://superuser.com/questions/358434/how-to-check-if-a-binary-is-32-or-64-bit-on-windows
  # https://reverseengineering.stackexchange.com/questions/6040/check-if-exe-is-64-bit/11373#11373
  describe command( <<-EOF

    function test-is64Bit {
      param(
        $FilePath="$env:windir\\system32\\cmd.exe"
      )

      [int32]$MACHINE_OFFSET = 4
      [int32]$PE_POINTER_OFFSET = 60

      [byte[]]$data = New-Object -TypeName System.Byte[] -ArgumentList 4096
      $stream = New-Object -TypeName System.IO.FileStream -ArgumentList ($FilePath, 'Open', 'Read')
      $stream.Read($data, 0, 4096) | out-null

      [int32]$PE_HEADER_ADDR = [System.BitConverter]::ToInt32($data, $PE_POINTER_OFFSET)
      [int32]$machineUint = [System.BitConverter]::ToUInt16($data, $PE_HEADER_ADDR + $MACHINE_OFFSET)
      $stream.Close()
      $stream.Dispose()
      $result = "" | select FilePath, FileType, Is64Bit
      $result.FilePath = $FilePath
      $result.Is64Bit = $false

      switch ($machineUint)
      {
          0      { $result.FileType = 'Native' }
          0x014c { $result.FileType = 'x86' }
          0x0200 { $result.FileType = 'Itanium' }
          0x8664 { $result.FileType = 'x64'; $result.is64Bit = $true; }
      }
      $result
    }
    test-is64Bit -filepath '#filepath' | format-list
  EOF
  ) do
    its(:stdout) { should  contain 'FileType : Native'}
    its(:stdout) { should  contain 'Is64Bit  : False'}
  end
end
