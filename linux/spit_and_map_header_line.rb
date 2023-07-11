require 'pp'
# Copyright (c) Serguei Kouzmine

header_line = '|A |  B |    C|D_E|'

# NOTE: will break into single char array
# column_names = header_line.split /|/
# PP.pp ((header_line.split /\|/).reject { |x| x !~ /\S/ }).map(&:strip!), $stderr
# NOTE: reject! can be destructive, it returns nil when no changes are made.
# to return the unchanged entry use reject
# see also: https://stackoverflow.com/questions/5878697/how-do-i-remove-blank-elements-from-an-array`
# this is verbose
# column_names = header_line.split( /\|/).reject { |x| x !~ /\S/ }.map(&:strip)
# PP.pp column_names, $stderr
column_names = header_line.split( /\|/).map(&:strip).reject(&:empty?)
PP.pp column_names, $stderr
columns = { }
column_names.each_index {|i| columns[column_names[i]] = i }

PP.pp columns, $stderr

columns = { }
column_names.each {|c| columns[c] = column_names.index(c) }
PP.pp columns, $stderr

