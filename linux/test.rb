require 'pp'
puts $stdout.isatty
test_line = '   TABLE_NAME              TABLE_SCHEMA   INDEX_NAME'
report_line = test_line
pp report_line
probe = Regexp.new('^\s*' + report_line.strip.gsub(/ +/, '\s+') + '\s*$', Regexp::IGNORECASE)
pp probe
result = probe.match(test_line)
pp result.to_a
probe = Regexp.new(report_line.strip.gsub(/ +/, '\s+'), Regexp::IGNORECASE)
pp probe
result = probe.match(test_line)
pp result.to_a
