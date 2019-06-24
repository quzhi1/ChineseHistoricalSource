# frozen_string_literal: true

counter = 0
chaptor = nil
line_buffer = ''
File.open('utf8/01史记.txt', 'r') do |f|
  f.each_line do |line|
    # skip first 4 lines
    if counter < 4
      counter += 1
      next
    elsif counter > 200
      break
    end

    # Check if it is a new chaptor
    new_chaptor = line[/●卷(.+)·(.+)第(.+)/, 2]
    if new_chaptor
      puts "Processing chaptor #{new_chaptor}"
      chaptor = new_chaptor
      counter += 1
      next
    end

    # if line[/^    /]
    #   # 
    #   line = line.strip
      
    # end
    # puts line
    counter += 1
  end
end
