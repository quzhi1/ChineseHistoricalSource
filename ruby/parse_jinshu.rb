# frozen_string_literal: true

require 'json'
require_relative './util.rb'

counter = 0
# the first chapter has some encoding problem, have to hack it
chapter = nil
in_chapter_title = false
json_array = []
File.open('utf8/05晋书.TXT', 'r') do |utf8_input|
  utf8_input.each_line do |line|
    # Check if it is a new chapter
    new_chapter = line[/\*\*\*\*\*\*\*\*\*\*\*\*(.*)第.*\s/, 1]
    if new_chapter
      in_chapter_title = true
      chapter = new_chapter.strip
      # puts chapter
      counter += 1
      next
    elsif in_chapter_title
      in_chapter_title = false
      # puts line.strip
      chapter += ' ' + line.strip
      puts "Processing chapter #{chapter}"
      counter += 1
      next
    end

    # Process each chapter
    unless line.strip.empty?
      # puts "Dumping: #{paragraph}"
      json_array << generate_paragraph_json('晋书', chapter, line.strip)
    end
    counter += 1

    # break if counter > 10
  end

  # puts json_array
  File.open('json/jinshu.json', 'w') do |json_output|
    json_output.write(JSON.pretty_generate(json_array))
  end
end
