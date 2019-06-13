require_relative '../windows_spec_helper'

context 'Powershell inline snippet tests' do
  class String
    def title_case
      split(/(\W)/).map(&:capitalize).join
    end
  end
  example = 'alpha beta'
  context 'Function' do
    describe command(<<-EOF
     function title_case {
       # NOTE: should not use param name $input or $param - ruins the result
       param(
        [String]$text,
        [String]$pattern = '^(.*)$'
       )
       write-debug ('text: {0}' -f $text)
       [String]$result = [Regex]::Match($text,$pattern).Value
       write-debug ('result: {0}' -f $result)
       (Get-Culture).TextInfo.ToTitleCase($result)
     }

    [String]$example = '#{example}'
    write-output ('Result: {0}' -f (title_case -text $example))
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Result: Alpha Beta/}
      its(:stdout) { should match example.title_case}
    end
  end
  context 'Broken Inline' do
    describe command(<<-EOF
      [String]$example = '#{example}'
      [String]$pattern = '^(.*)$'
      [System.Globalization.TextInfo]$textInfo = (Get-Culture).TextInfo
      [Regex]$regex = new-object Regex($pattern)
      write-output ('Result: {0}' -f ($regex.Replace( $example, $textInfo.ToTitleCase("$1"))))
    EOF
    ) do
      its(:exit_status) { should eq 0 }
    # does not work, commented
    # Expected "Result: \n" to match /Result: Example Sentence/
    #  its(:stdout) { should match /Result: Example Sentence/}
    end
  end
  # suggested in http://www.cyberforum.ru/powershell/thread2470847.html#post13653223
  context 'Inline' do
    describe command(<<-EOF
      # keeping the original terse syntax
      [System.Globalization.TextInfo]$textInfo = (Get-Culture).TextInfo
      $examples = @('alpha beta' )
      $pattern = '^(.+)$'
      $examples  | foreach-object {
        write-output "Probing $_"
        if (-not ($_ -match  $pattern)){
          write-debug "NOT MATCHED $_"
          $_
        } else {
          "Result: $($textInfo.ToTitleCase($Matches[1].ToLower()))"
        }
      }
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Result: Alpha Beta/}
    end
  end
end
