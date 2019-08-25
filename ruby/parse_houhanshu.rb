# frozen_string_literal: true

require 'json'

def generate_paragraph_json(source, chapter, text)
  json_obj = {}
  json_obj['source'] = source
  json_obj['chapter'] = chapter
  json_obj['text'] = text
  json_obj
end

counter = 0
# the first chapter has some encoding problem, have to hack it
chapter = nil
json_array = []
File.open('utf8/后汉书乱序版.TXT', 'r') do |utf8_input|
  utf8_input.each_line do |line|
    # Check if it is a new chapter
    new_chapter = line[/后汉书 - (.*第.*) - 中国古典文学/, 1]
    if new_chapter
      chapter = new_chapter.strip
      puts "Processing chapter #{chapter}"
      counter += 1
      next
    end

    # Process each chapter
    line.split.each do |paragraph|
      # puts "Dumping: #{paragraph}"
      json_array << generate_paragraph_json('后汉书', chapter, paragraph)
    end
    counter += 1

    # break if counter > 10
  end

  # puts json_array
  File.open('json/houhanshu.json', 'w') do |json_output|
    json_output.write(JSON.pretty_generate(json_array))
  end
end
