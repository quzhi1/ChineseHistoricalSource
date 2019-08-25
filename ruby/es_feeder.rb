# frozen_string_literal: true

require 'io/console'
require 'elasticsearch'
require 'json'

# Feed one history source
class EsFeeder
  def initialize
    @client = Elasticsearch::Client.new(url: url, log: false)
  end

  def feed_one(json)
    @client.create index: 'history_source',
                   type: '_doc',
                   body: json
  end

  def url
    # This block is only for Bonsai
    # puts 'Username:'
    # username = gets
    # username = username.strip
    # password = STDIN.getpass "Enter Password:\n"
    # password = password.strip
    # url = "https://#{username}:#{password}\
    # @historyengine-3812216299.us-west-2.bonsaisearch.net:443"
    # puts url

    # This is for local testing
    url = 'http://localhost:9200'

    url
  end

  def run(file_name)
    threads = []
    File.open(file_name, 'r') do |file|
      json_array = JSON.load(file) # rubocop:disable Security/JSONLoad
      json_array.each do |json|
        threads << Thread.new { feed_one(json) }
      end
    end
    threads.each(&:join)
  end

  def delete_source(source)
    @client.delete_by_query(
      index: 'history_source',
      body: { query: { bool: { must: [{ match: { source: source } }] } } }
    )
  end
end

EsFeeder.new.run('json/houhanshu.json')
# puts EsFeeder.new.delete_source('')
