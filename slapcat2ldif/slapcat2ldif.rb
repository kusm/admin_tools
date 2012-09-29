#!/usr/bin/ruby -Ku
# -*- coding: utf-8; -*-

File.open('needless-attributes.txt', 'r') do |file|
	attrs = file.read().chomp.gsub(/\s*\n\r?/, '|')
	$exclude_pattern = Regexp.new("^(#{attrs}):\\s[^\\n]*$")
end

while line = STDIN.gets
	if (not (line.chomp =~ $exclude_pattern)) then
		STDOUT.puts line
	end
end

