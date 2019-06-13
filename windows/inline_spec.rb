require_relative '../windows_spec_helper'

context 'Powershell inline snippet tests' do
  class String
    def title_case
      split(/(\W)/).map(&:capitalize).join
    end
  end
  example = 'example sentence'
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
      its(:stdout) { should match /Result: Example Sentence/}
      its(:stdout) { should match example.title_case}
    end
  end
  context 'Inline' do
    # does not work:
    # Expected "Result: \n" to match /Result: Example Sentence/
    describe command(<<-EOF
      [String]$example = '#{example}'
      [String]$pattern = '^(.*)$'
      [Regex]$regex = new-object Regex($pattern)
      write-output ('Result: {0}' -f ($regex.Replace( $example, (Get-Culture).TextInfo.ToTitleCase("$1"))))
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Result: Example Sentence/}
    end
  end
end
