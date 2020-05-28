# typed: strict
# frozen_string_literal: true

require 'json'
require 'pry'

module HtmlParser
  extend T::Sig

  sig do
    params(
      source_page: Nokogiri::HTML::Document,
      count: Integer,
    )
    .returns(String)
  end
  def get_book_name(source_page, count)
    chapter_name_xpath = '/html/body/div[3]/div[3]/article/ul/li[%<count>s]/span[2]/a/@data-title'
                         .format(count: count)
    source_page.xpath(chapter_name_xpath).text.strip
  end

  sig do
    params(
      source_page: Nokogiri::HTML::Document,
      count: Integer,
    )
    .returns(String)
  end
  def get_book_url(source_page, count)
    chapter_name_xpath = '/html/body/div[3]/div[3]/article/ul/li[%<count>s]/span[2]/a/@href'
                         .format(count: count)
    source_page.xpath(chapter_name_xpath).text.strip
  end

  sig do
    params(
      source_page: Nokogiri::HTML::Document,
      count: Integer,
    )
    .returns(String)
  end
  def get_translation_url(source_page, count)
    chapter_name_xpath = '/html/body/div[3]/div[3]/article/ul/li[%<count>s]/span[3]/a/@href'
                         .format(count: count)
    source_page.xpath(chapter_name_xpath).text.strip
  end

  sig do
    params(
      source_page: Nokogiri::HTML::Document,
      count: Integer,
    )
    .returns(String)
  end
  def get_chapter_name(source_page, count)
    chapter_name_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a'
                         .format(count: count)
    source_page.xpath(chapter_name_xpath).text.strip
  end

  sig do
    params(
      source_page: Nokogiri::HTML::Document,
      count: Integer,
    )
    .returns(String)
  end
  def get_chapter_url(source_page, count)
    chapter_url_xpath = '/html/body/div[3]/div[3]/ul/li[%<count>s]/a/@href'
                        .format(count: count)
    source_page.xpath(chapter_url_xpath).text.strip
  end
end
