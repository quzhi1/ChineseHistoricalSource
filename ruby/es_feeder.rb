# frozen_string_literal: true

require 'io/console'
require 'elasticsearch'
require 'json'

def feed_one(client, json)
  client.create index: 'basic',
                type: '_doc',
                body: json
end

puts 'Username:'
username = gets
username = username.strip
password = STDIN.getpass "Enter Password:\n"
password = password.strip
puts 'Input file:'
input_file = gets
input_file = input_file.strip
url = "https://#{username}:#{password}@historyengine-3812216299.us-west-2.bonsaisearch.net:443" # rubocop:disable Metrics/LineLength
# puts url

client = Elasticsearch::Client.new(url: url, log: false)

File.open(input_file, 'r') do |file|
  json_array = JSON.load(file) # rubocop:disable Security/JSONLoad
  counter = 1
  json_array.each do |json|
    if (counter % 10).zero?
      puts "Processing paragraphs: #{counter}/#{json_array.size}"
    end
    feed_one(client, json)
    counter += 1
  end
end
