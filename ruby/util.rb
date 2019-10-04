# frozen_string_literal: true

require 'json'

def generate_paragraph_json(source, chapter, text)
  not_nil_nor_empty([source, chapter, text])
  {
    'source' => source,
    'chapter' => chapter,
    'text' => text
  }
end

private def not_nil_nor_empty(params)
  params.each { |param| raise if param.nil? || param.empty? }
end
