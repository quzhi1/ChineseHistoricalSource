# frozen_string_literal: true

require 'json'
require_relative './util.rb'

counter = 0
# the first chapter has some encoding problem, have to hack it
chapter = nil
json_array = []
flip = false
File.open('utf8/10魏书.TXT', 'r') do |utf8_input|
  utf8_input.each_line do |line|
    # puts "Processing line #{line}"
    # Check if it is a new chapter
    if line.include? '********'
      flip = true
      counter += 1
      next
    elsif flip
      flip = false
      chapter_parts = line.scan(/(\S+)第\S+\s(.*)/)
      chapter = chapter_parts[0][0] + ' ' + chapter_parts[0][1].strip
      puts "Processing chapter #{chapter}"
      counter += 1
      next
    end

    # Process each chapter
    unless line.strip.empty?
      # puts "Dumping: #{line.strip}"
      json_array << generate_paragraph_json('魏书', chapter, line.strip)
    end
    counter += 1

    # break if counter > 10
  end

  # # puts json_array
  File.open('json/weishu.json', 'w') do |json_output|
    json_output.write(JSON.pretty_generate(json_array))
  end
end
