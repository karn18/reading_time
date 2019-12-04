# reading_time
#
# A Liquid filter to estimate how long a passage of text will take to read
#
# https://github.com/bdesham/reading_time
#
# Copyright (c) 2013, 2015 Benjamin D. Esham. This program is released under the
# ISC license, which you can find in the file LICENSE.md.

require 'nokogiri'

module ReadingTime
  def config
    @config ||= @context.registers[:site].config.fetch("reading_time", {})
  end

  def count_words(html)
    use_thai_nlp = config.fetch('thai_nlp', false)
    if use_thai_nlp
      tokenize_words(html)
    else
      words(html).length
    end
  end

  def reading_time(html)
    reading_speed = config.fetch('reading_speed', 270)
    (count_words(html) / reading_speed).ceil
  end

  private

  def text_nodes(root)
    ignored_tags = %w[
      area audio canvas code embed footer form img
      map math nav object pre script svg table track video
    ]

    texts = []
    root.children.each { |node|
      if node.text?
        texts << node.text
      elsif !ignored_tags.include? node.name
        texts.concat text_nodes node
      end
    }
    texts
  end

  def tokenize_words(html)
    fragment = Nokogiri::HTML.fragment html
    cmd = `python word_tokenizer.py "#{text_nodes(fragment)}"`
    cmd.to_i
  end

  def words(html)
    fragment = Nokogiri::HTML.fragment html
    text_nodes(fragment).map { |text| text.scan(/[\p{L}\p{M}'‘’]+/) }.flatten
  end
end

Liquid::Template.register_filter(ReadingTime)
