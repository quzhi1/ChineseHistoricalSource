# typed: strict
# frozen_string_literal: true

require 'concurrent-ruby'
require 'elasticsearch'
require 'io/console'
require 'json'
require 'sorbet-runtime'

# Feed one history source
class EsFeeder
  extend T::Sig

  URL = 'http://localhost:9200'

  sig { void }
  def initialize
    @client = T.let(
      Elasticsearch::Client.new(
        url: URL,
        log: false,
        user: 'elastic',
        password: 'changeme'
      ),
      Elasticsearch::Transport::Client
    )
  end

  sig { params(json: T::Hash[String, String]).void }
  def feed_one(json)
    # puts "Feeding: #{json}"
    @client.create index: 'history_source',
                   type: '_doc',
                   body: json
  end

  sig { params(file_name: String).void }
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

  sig { params(file_name: String).returns(Integer) }
  def doc_count(file_name)
    File.open(file_name, 'r') do |file|
      JSON.load(file).size # rubocop:disable Security/JSONLoad
    end
  end

  sig { params(source: String).void }
  def delete_source(source)
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

  sig { void }
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

  sig { params(source: String).returns(Integer) }
  def count_by_source(source)
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

  sig { void }
  def ingest_all
    Dir['json/*.json'].each { |file_name| EsFeeder.new.run(file_name) }
  end

  sig { void }
  def post_run_test
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
# Ingest one source
# es_feeder.run('json/宋史.json')

# Ingest all sources
es_feeder.ingest_all

# Count local doc and elasticsearch doc
# puts es_feeder.doc_count('json/旧五代史.json')
# puts es_feeder.count_by_source('旧五代史')

# Delete one souce
# puts es_feeder.delete_source('宋史')

# Delete all sources
# puts es_feeder.delete_all

# Test if any document missing
es_feeder.post_run_test
