$rootPath =  '\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'

$appPathsData = @{}
pushd HKLM:
cd $rootPath
$appPaths = get-childitem . | select-object -property name;
$appPaths| foreach-object {

  $appPAth = $_

  pushd $rootPath
  $path = (($appPath.'name') -replace 'HKEY_LOCAL_MACHINE' , '') -replace '^.*\\', ''
  write-debug  "Get-ItemProperty -path ${path} -name '(default)'"
  try {
    $data = Get-ItemProperty -path $path -name '(default)' -errorAction stop
  }catch [Exception] {
    # e.g.
    # Get-ItemProperty : Property (default) does not exist at path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmmgr32.exe.
  }
  if ($data -ne $null) {
    $appPathsData.add(($path -replace '\..*$', '' ), $data.'(default)')
  }
  popd
}
popd
c:
$appPathsData
$appPathsData.keys |  foreach-object {
  $name = $_
  $path = $appPathsData[$name]
  start-process  cmd.exe -argumentlist @('/c', 'start' , $name )
  start-sleep -seconds 10
  get-process | where-object { $_.ProcessName -match $name } | select-object -Property id,path
  # TODO: assertion, termination
}