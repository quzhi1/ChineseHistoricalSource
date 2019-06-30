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
chaptor = nil
line_buffer = StringIO.new
json_array = []
File.open('utf8/01史记.txt', 'r') do |utf8_input|
  utf8_input.each_line do |line|
    # Check if it is a new chaptor
    new_chaptor = line[/●卷(.+)·(.+)第(.+)/, 2]
    if new_chaptor
      puts "Processing chaptor #{new_chaptor}"
      chaptor = new_chaptor
      counter += 1
      next
    end

    # 4 space before paragraph start
    # puts "Processing line: #{line}"
    if line[/^    /]
      if line_buffer.size != 0 # rubocop:disable Style/ZeroLengthPredicate
        text = line_buffer.string.clone
        # puts "Dumping: #{text}"
        json_array << generate_paragraph_json('史记', chaptor, text)
        line_buffer.truncate(0)
        line_buffer.rewind
      end
    end
    line_buffer << line.strip
    counter += 1
  end

  # puts json_array
  File.open('json/shiji.json', 'w') do |json_output|
    json_output.write(JSON.pretty_generate(json_array))
  end
end
