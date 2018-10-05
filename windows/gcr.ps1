Function Get-ComRegistered {
# https://msdn.microsoft.com/en-us/library/microsoft.win32.registrykey(v=vs.110).aspx
    [CmdletBinding()]
    param(
      [String]$ComputerName = $Env:ComputerName,
      [Switch]$DoNotUseCache
    )  

  begin {

   If(-not $Script:ComRegisteredCache) {
      # The Registry entrys are changing only if a new COM Component ist registered or unregistered
      # This happens not very often so we use a Variable to hold the Registered COM components from Registry
      # as Array which is used as a static cache
      $Script:ComRegisteredCache = [System.Collections.ArrayList]@()
    }
    Function InternalWorkHorse {
      
      [CmdletBinding()]
      param(
        [String]$ComputerName
      )

      Try {
	      $HiveRegistryKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::ClassesRoot,[Microsoft.Win32.RegistryView]::Default)
	      } Catch {
	      Write-Error $_
	      Return $Null
      }
      
      # Create array with names of registry keys to visit
      $ClsidRegistryKeys = @('CLSID')

      # test if the Wow6432Node key exist
      Try{
        $SubKey = $HiveRegistryKey.OpenSubKey('Wow6432Node\CLSID123')
        $SubKey.GetValue('')
        # Wow6432Node exist add to list
        $ClsidRegistryKeys += 'Wow6432Node\CLSID'
      } Catch {}


      # clear the cache to refill it with this function
      ([System.Collections.ArrayList]$Script:ComRegisteredCache).Clear()

      ForEach($ClsidRegistryKey in $ClsidRegistryKeys) {

            $ClsidRegistryKeyChildName = ($ClsidRegistryKey -split '\\')[(($ClsidRegistryKey -split '\\').count -1)]

            $SubKeyNames = $HiveRegistryKey.OpenSubKey($ClsidRegistryKey).GetSubKeyNames()

            $ParentRegistryKey = New-Object -TypeName PsObject -Property @{
                          Path = "HKEY_CLASSES_ROOT\$ClsidRegistryKey"
                          ParentPath = 'HKEY_CLASSES_ROOT'
                          ChildName = $ClsidRegistryKeyChildName
                          IsContainer = $True
                          SubKeyCount = $SubKeyNames.Count
                          View = 'Default'
                          Name = "HKEY_CLASSES_ROOT\$ClsidRegistryKey"
                        }
            
            Write-Verbose "Processing Registry Key: HKEY_CLASSES_ROOT\$ClsidRegistryKey" 
            
            # process each key inside the Registry
            ForEach($SubKeyName in $SubKeyNames)
            {

              Write-Verbose "Processing Sub-Registry Key: HKEY_CLASSES_ROOT\$ClsidRegistryKey\$SubKeyName" 

              # create a new empty Object to return the result
              # because New-Object is very slow to create a new PSObject we use the '' | Select-Object trick here
              # '' | Select-Object trick here; is a fast way to create a new empty Object with PowerShell 2.0
              $ResultObject = '' | Select-Object ProgID,ClsID,VersionIndependentProgID,ComputerName,ParentRegistryKey,FriendlyClassName,InprocHandler,InprocHandler32,InprocServer32,LocalServer,LocalServer32,LocalService
              $ResultObject.PStypenames.Clear()
              $ResultObject.PStypenames.Add('System.Management.Automation.PSCustomObject')
              $ResultObject.PStypenames.Add('System.Object')
    
              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\ProgId")
                $ProgId = $SubKey.GetValue('')
              }
              Catch { $ProgId = '' }

              $ResultObject.ProgID = $ProgId
              $ResultObject.ParentRegistryKey = $ParentRegistryKey
              $ResultObject.Computername = $ComputerName

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\VersionIndependentProgID")
                $ResultObject.VersionIndependentProgID = $SubKey.GetValue('')
              }
              Catch { $ResultObject.VersionIndependentProgID = '' }

              Try{
                $ResultObject.ClsID = "{$(([Guid]$SubKeyName).ToString())}"
              }
              Catch {
                Write-Warning "ClsID is Empty on ProgID: $ProgId RegistryKey: HKEY_CLASSES_ROOT\$ClsidRegistryKey\$SubKeyName " 
                continue
              }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName")
                $ResultObject.FriendlyClassName = $SubKey.GetValue('')
              }
              Catch { $ResultObject.FriendlyClassName = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\InprocHandler")
                $ResultObject.InprocHandler = $SubKey.GetValue('')
              }
              Catch { $ResultObject.InprocHandler = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\InprocHandler32")
                $ResultObject.InprocHandler32 = $SubKey.GetValue('')
              }
              Catch { $ResultObject.InprocHandler32 = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\InprocServer32")
                $ResultObject.InprocServer32 = $SubKey.GetValue('')
              }
              Catch { $ResultObject.InprocServer32 = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\LocalServer")
                $ResultObject.LocalServer = $SubKey.GetValue('')
              }
              Catch { $ResultObject.LocalServer = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\LocalServer32")
                $ResultObject.LocalServer32 = $SubKey.GetValue('')
              }
              Catch { $ResultObject.LocalServer32 = '' }

              Try{
                $SubKey =  $HiveRegistryKey.OpenSubKey("$ClsidRegistryKey\$SubKeyName\LocalService")
                $ResultObject.LocalService = $SubKey.GetValue('')
              }
              Catch { $ResultObject.LocalService = '' }

            # return resulting Object and 
            # read the Registered COM components fresh from Registry into the Array which is used as a static cache
            [void]([System.Collections.ArrayList]$Script:ComRegisteredCache).Add($ResultObject)
            $ResultObject| where-object {( $_.InprocServer32 -like 'C:\\Pr.*' ) }   | select-object -property FriendlyClassName,ClsID,InprocServer32 | format-list

            } # end of ForEach($SubKeyName in $SubKeyNames) 32Bit hive

      }
    
    } # end of function InternalWorkHorse block
  
  } # end of begin block
  process {
    # nothing here!
  } # end of process block
  end {

    # (re)read values from registry if the cache is empty or the cache should not be used or the All setting has changed
    If((-not $Script:ComRegisteredCache.Count -gt 0) -or $DoNotUseCache.IsPresent ) {
      
      Write-Verbose 'Reading the Registry entrys to the cache'
      # read the Registered COM components fresh from Registry 
      InternalWorkHorse -ComputerName $ComputerName

    } else {
    
      Write-Verbose 'Using the cache to output the Result'
      # return Result from cache

      $Script:ComRegisteredCache  | select-object -property FriendlyClassName,ClsID,InprocServer32 | foreach-object {if (( $_.FriendlyClassName -match 'Virt.*' )) {  write-output $_.FriendlyClassName}}
       $Script:ComRegisteredCache  | select-object -property FriendlyClassName,ClsID,InprocServer32|  where-object {( $_.FriendlyClassName -like 'Photo.*' ) }    | select-object -first 100  | select-object -property *| format-list	
#      $Script:ComRegisteredCache | where-object {( $_.InprocServer32 -like 'C:\\Pr.*' ) }   | select-object -property FriendlyClassName,ClsID,InprocServer32 | format-list
    }
    
  } # end of end block
}

