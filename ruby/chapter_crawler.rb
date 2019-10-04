# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'json'
require 'powerpack'
require_relative './util.rb'

# Simple web crawler for this project
class ChapterCrawler
  URL_FORMAT = 'https://duguoxue.com/ershisishi/%<subdomain>s/'

  SOURCE_SUBDOMAIN = {
    '史记' => 'shiji',
    '汉书' => 'hanshu',
    '后汉书' => 'houhanshu',
    '三国志' => 'sanguozhi',
    '晋书' => 'jinshu',
    '宋书' => 'songshu',
    '南齐书' => 'nanqishu',
    '梁书' => 'liangshu',
    '陈书' => 'chenshu',
    '魏书' => 'weishu',
    '北齐书' => 'beiqishu',
    '周书' => 'zhoushu',
    '隋书' => 'suishu',
    '南史' => 'nanshi',
    '北史' => 'beishi',
    '旧唐书' => 'jiutangshu',
    '新唐书' => 'xintangshu',
    '旧五代史' => 'jiuwudaishi',
    '新五代史' => 'xinwudaishi',
    '宋史' => 'songshi',
    '辽史' => 'liaoshi',
    '金史' => 'jinshi',
    '元史' => 'yuanshi',
    '明史' => 'mingshi'
  }.freeze

  def run
    SOURCE_SUBDOMAIN.each do |source, subdomain|
      json_array = process_source(source, subdomain)

      # puts json_array
      File.open("json/#{source}.json", 'w') do |json_output|
        json_output.write(JSON.pretty_generate(json_array))
      end
    end
  end

  def process_source(source, subdomain) # rubocop:disable Metrics/MethodLength
    puts "Processing #{source}"
    source_page = get_source_page(subdomain)
    json_array = []
    count = 1
    loop do
      chapter_name = get_chapter_name(source_page, count)
      chapter_url = get_chapter_url(source_page, count)
      break if chapter_url.empty? || chapter_name.empty?

      process_chapter(source, chapter_url, chapter_name, json_array)
      count += 1
    end
    json_array
  end

  def get_source_page(subdomain)
    url = URL_FORMAT.format(subdomain: subdomain)
    Nokogiri::HTML(open(url)) # rubocop:disable Security/Open
  end

  def get_chapter_name(source_page, count)
    chapter_name_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a'
                         .format(count: count)
    source_page.xpath(chapter_name_xpath).text.strip
  end

  def get_chapter_url(source_page, count)
    chapter_url_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a/@href'
                        .format(count: count)
    source_page.xpath(chapter_url_xpath).text.strip
  end

  def process_chapter(source, chapter_url, chapter_name, json_array)
    page = Nokogiri::HTML(open(chapter_url)) # rubocop:disable Security/Open
    # chapter = fetch_chapter_name(page)
    puts "\tProcessing chapter #{chapter_name}"
    process_paragraphs(source, chapter_name, page, json_array)
  end

  def process_paragraphs(source, chapter, page, json_array)
    count = 1
    loop do
      para_xpath = '/html/body/div[3]/div[3]/p[%<para>s]/text()'
                   .format(para: count)
      para = page.xpath(para_xpath).text.strip
      break if para.empty?

      # puts "\t\t#{para}"
      json_array << generate_paragraph_json(source, chapter, para)
      count += 1
    end
  end
end

ChapterCrawler.new.run
