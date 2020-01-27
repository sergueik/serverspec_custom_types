# based on: http://www.cyberforum.ru/powershell/thread2574556.html
# The code below ws removed and replaced with a more cryptic version i the original post

# пересечение
$one = @('A', 'B','C', 'D', 'E', 'F')
$two = @('A', 'C','E', 'G', 'I', 'K')
write-output ('Intersection of ' + ($one -join ',' ) + ' and ' + ($two -join ',') )

# requires certain Powershell version just for syntax sugar
$three = $one.where{ $two -contains $_ }
write-output ($three -join ',')
# try
try{
  $three = Compare-Object $one $two -PassThru -IncludeEqual -ExcludeDifferent [Linq.Enumerable]::Intersect([String[]]$one, [String[]]$two)
  write-output ($three -join ',')
} catch [exception]{
  Write-Output ("Exception (ignored):`n{0}" -f (($_.Exception.Message) -split "`n")[0])
}

write-output ('Concatenation of ' + ($one -join ',' ) + ' and ' + ($two -join ',') )
# конкатенация

$three = $one + $two
write-output ($three -join ',')

$three = [Linq.Enumerable]::Concat([String[]]$one, [String[]]$two)
write-output ($three -join ',')


# объединение
write-output ('Consolidation (unification) of ' + ($one -join ',' ) + ' and ' + ($two -join ',') )
# конкатенация
$three = $one + $two | Select-Object -Unique
write-output ($three -join ',')
try{
  $tree = Compare-Object $one $two -PassThru -IncludeEqual | Sort-Object [Linq.Enumerable]::Union([String[]]$one, [String[]]$two)
  write-output ($three -join ',')
} catch [exception]{
  Write-Output ("Exception (ignored):`n{0}" -f (($_.Exception.Message) -split "`n")[0])
}
# исключение
write-output ('Substraction of ' + ($one -join ',' ) + ' and ' + ($two -join ',') )
$three = $one.Where{$two -notcontains $_}
write-output ($three -join ',')
# (Compare-Object $one $two).Where{$_.SideIndicator -eq '<='}.InputObject [Linq.Enumerable]::Except([String[]]$one, [String[]]$two)

# исключающее объединение (симметричная разность)
write-output ('Symmetric substraction of ' + ($one -join ',' ) + ' and ' + ($two -join ',') )
$three= $one.Where{$_ -notin $two} + $two.Where{ $_ -notin $one }
write-output ($three -join ',')

try{
  $three = Compare-Object $one $two -PassThru | Sort-Object [Linq.Enumerable]::Union( [Linq.Enumerable]::Except([String[]]$one, [String[]]$two), [Linq.Enumerable]::Except([String[]]$two, [String[]]$one))
  write-output ($three -join ',')
} catch [exception]{
  Write-Output ("Exception (ignored):`n{0}" -f (($_.Exception.Message) -split "`n")[0])
}
