[System.Globalization.TextInfo]$textInfo = (Get-Culture).TextInfo
 # keeping the original terse syntax
 # mockup of JSON fragment
 $examples = @('alpha beta' )
 $pattern = '^(.+)$'
 $examples  | foreach-object {
   write-output "Probing $_"
   if (-not ($_ -match  $pattern)){
     write-debug "NOT MATCHED $_ "
     $_
   } else { 
     $textInfo.ToTitleCase($Matches[1].ToLower())
  }
 } 
 
