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
    # puts "Feeding: #{json}"
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
    url = 'http://127.0.0.1:9200'

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
    pool.shutdown
    pool.wait_for_termination
  end

  def doc_count(file_name)
    File.open(file_name, 'r') do |file|
      JSON.load(file).size # rubocop:disable Security/JSONLoad
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

  def count_by_source(source) # rubocop:disable Metrics/MethodLength
    res = @client.count(
      index: 'history_source',
      body: {
        query: {
          bool: {
            must: [
              {
                match_phrase: {
                  'source.keyword' => {
                    query: source
                  }
                }
              }
            ]
          }
        }
      }
    )
    res['count']
  end

  def ingest_all
    Dir['json/*.json'].each { |file_name| EsFeeder.new.run(file_name) }
  end

  def post_run_test # rubocop:disable Metrics/MethodLength
    Dir['json/*.json'].each do |file_name|
      source = file_name.sub('json/', '').sub('.json', '')
      local_count = doc_count(file_name)
      es_count = count_by_source(source)
      if es_count != local_count
        raise "#{source} ingestion incomplete. "\
          "Expected: #{local_count}. Actual: #{es_count}"
      else
        puts "#{source} ingestion is sucessful"
      end
    end
  end
end

es_feeder = EsFeeder.new

# rubocop:disable Style/AsciiComments
# Ingest one source
# es_feeder.run('json/宋史.json')

# Ingest all sources
es_feeder.ingest_all

# Count local doc and elasticsearch doc
# puts es_feeder.doc_count('json/旧五代史.json')
# puts es_feeder.count_by_source('旧五代史')

# Delete one souce
# puts es_feeder.delete_source('史记')

# Delete all sources
# puts es_feeder.delete_all

# rubocop:enable Style/AsciiComments

# Test if any document missing
es_feeder.post_run_test
