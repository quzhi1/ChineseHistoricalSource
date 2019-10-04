# frozen_string_literal: true

require 'io/console'
require 'concurrent-ruby'
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
    puts "Processing #{file_name}"
    pool = Concurrent::FixedThreadPool.new(12)
    File.open(file_name, 'r') do |file|
      json_array = JSON.load(file) # rubocop:disable Security/JSONLoad
      json_array.each do |json|
        pool.post { feed_one(json) }
      end
    end
  end

  def delete_source(source) # rubocop:disable Metrics/MethodLength
    @client.delete_by_query(
      index: 'history_source',
      body: {
        query: {
          bool: {
            must: [
              {
                match: { source: source }
              }
            ]
          }
        }
      }
    )
  end

  def delete_all
    @client.delete_by_query(
      index: 'history_source',
      body: {
        query: {
          match_all: {}
        }
      }
    )
  end

  def ingest_all
    Dir['json/*.json'].each { |file_name| EsFeeder.new.run(file_name) }
  end
end

# EsFeeder.new.run('json/weishu.json')
# puts EsFeeder.new.delete_source('')
# puts EsFeeder.new.delete_all
EsFeeder.new.ingest_all
