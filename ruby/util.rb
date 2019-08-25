# frozen_string_literal: true

require 'json'

def generate_paragraph_json(source, chapter, text)
  json_obj = {}
  json_obj['source'] = source
  json_obj['chapter'] = chapter
  json_obj['text'] = text
  json_obj
end
