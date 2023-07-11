# origin: http://www.cyberforum.ru/powershell/thread1950301.html
# Copyright (c) Serguei Kouzmine
function Get-MembersLocalAdmins {
Param (
    [Parameter(ValueFromPipeline=$true, ValueFrompipelinebyPropertyName=$True)]
    [STring[]]$computername = $env:COMPUTERNAME
    )

PROCESS {
    if ($computername.count -gt 1) {
        $computername | % { $_ } | Get-MembersLocalAdmins
    } else {
        $winnt = [ADSI]"WinNT://$computername, Computer"

        $winnt.Children | ? { $_.schemaClassName -eq "group"} |

        where { $_.objectsid.tostring() -eq "1 2 0 0 0 0 0 5 32 0 0 0 32 2 0 0" } |
        foreach { $_.psbase.invoke("Members") } |
        foreach {
            ( $_.GetType().InvokeMember('ADspath', 'GetProperty', $null, $_, $null).Replace('WinNT://', '').split("/") | select -last 2 ) -join "/"
         }
    }

}
<#
.Synopsis
     Получает локальных администраторов
.Example
    Get-MembersLocalAdmins comp1,comp2
#>
}