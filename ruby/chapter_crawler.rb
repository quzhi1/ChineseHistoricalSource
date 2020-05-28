# typed: strict
# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'powerpack'
require 'sorbet-runtime'
require_relative './html_parser.rb'

# Simple web crawler for this project
class ChapterCrawler
  extend T::Sig
  include HtmlParser
  ROOT_URL = 'https://duguoxue.com/ershisishi'

  sig { void }
  def run
    book_list = get_book_list

    book_list.each do |book_hash|
      json_array = process_source(
        book_hash[:book_name],
        book_hash[:book_url],
        book_hash[:translation_url]
      )

      # puts json_array
      File.open("json/#{book_hash[:book_name]}.json", 'w') do |json_output|
        json_output.write(JSON.pretty_generate(json_array))
      end
    end
  end

  sig do
    params(
      source: String,
      book_url: String,
      translation_url: String
    )
    .returns(
      T::Array[
        {
          'source' => String,
          'chapter' => String,
          'text' => String,
          'chapter_url' => String,
          'chapter_translation' => String
        }
      ]
    )
  end
  def process_source(source, book_url, translation_url)
    puts "Processing #{source}"

    # Translation hash: {'五帝本纪' => 'https://duguoxue.com/ershisishi/2692.html', ...}
    translation_hash = get_translation_hash(translation_url)

    source_page = Nokogiri::HTML(URI.parse(book_url).open)
    json_array = []
    count = 1
    loop do
      chapter_name = get_chapter_name(source_page, count)
      chapter_url = get_chapter_url(source_page, count)
      # Sometimes the translation title is 五帝本纪, but the title is 卷一·五帝本纪第一
      # We need to run substring check
      translation_pair = translation_hash.find { |key, _| chapter_name.include?(key) }
      break if chapter_url.empty? || chapter_name.empty?
      if translation_pair
        chapter_translation = translation_pair[1]
      else
        puts "No translation found for chapter #{{ source: source, chapter_name: chapter_name }}"
        chapter_translation = translation_url
      end

      process_chapter(source, chapter_url, chapter_name, chapter_translation, json_array)
      count += 1
    end
    json_array
  end

  sig do
    returns(
      T::Array[
        { book_name: String, book_url: String, translation_url: String }
      ]
    )
  end
  def get_book_list
    source_page = Nokogiri::HTML(URI.parse(ROOT_URL).open)
    count = 2
    json_array = []
    loop do
      book_name = get_book_name(source_page, count)
      book_url = get_book_url(source_page, count)
      translation_url = get_translation_url(source_page, count)
      break if book_name.empty? || book_url.empty?

      json_array << { book_name: book_name, book_url: book_url, translation_url: translation_url }
      count += 1
    end
    json_array
  end

  # Translation hash: {'五帝本纪' => 'https://duguoxue.com/ershisishi/2692.html'}
  sig do
    params(translation_url: String)
    .returns(T::Hash[String, String])
  end
  def get_translation_hash(translation_url)
    puts "Looking up translation #{translation_url}"
    count = 1
    source_page = Nokogiri::HTML(URI.parse(translation_url).open)
    translation_hash = {}
    loop do
      chapter_name_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a/text()'
                           .format(count: count)
      chapter_translation_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a/@href'
                                  .format(count: count)
      chapter_name = source_page.xpath(chapter_name_xpath).text.strip
      chapter_translation_url = source_page.xpath(chapter_translation_xpath).text.strip
      break if chapter_name.empty? || chapter_translation_url.empty?
      translation_hash[chapter_name] = chapter_translation_url
      count += 1
    end
    translation_hash
  end

  sig do
    params(
      source: String,
      chapter_url: String,
      chapter_name: String,
      chapter_translation: String,
      json_array: T::Array[{
        'source' => String,
        'chapter' => String,
        'text' => String,
        'chapter_url' => String,
        'chapter_translation' => String
      }]
    )
    .returns(T.untyped)
  end
  def process_chapter(source, chapter_url, chapter_name, chapter_translation, json_array)
    page = Nokogiri::HTML(open(chapter_url)) # rubocop:disable Security/Open
    # chapter = fetch_chapter_name(page)
    puts "\tProcessing chapter #{chapter_name}"
    count = 1
    loop do
      para_xpath = '/html/body/div[3]/div[3]/p[%<para>s]/text()'
                   .format(para: count)
      para = page.xpath(para_xpath).text.strip
      break if para.empty?

      # puts "\t\t#{para}"
      json_array << {
        'source' => source,
        'chapter' => chapter_name,
        'text' => para,
        'chapter_url' => chapter_url,
        'translation' => chapter_translation
      }
      count += 1
    end
  end
end

ChapterCrawler.new.run
