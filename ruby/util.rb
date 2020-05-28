# frozen_string_literal: true

require 'json'
require 'pry'

def generate_paragraph_json(source, chapter, text, chapter_url, chaptor_translation)
  not_nil_nor_empty([source, chapter, text, chapter_url]) # TODO: remove after sorbet
  {
    'source' => source,
    'chapter' => chapter,
    'text' => text,
    'chapter_url' => chapter_url,
    'chaptor_translation' => chaptor_translation
  }
end

private def not_nil_nor_empty(params)
  params.each { |param| raise if param.nil? || param.empty? }
end
