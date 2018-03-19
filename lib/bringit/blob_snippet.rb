# frozen_string_literal: true

module Bringit
  class BlobSnippet
    include Linguist::BlobHelper

    attr_accessor :ref
    attr_accessor :lines
    attr_accessor :filename
    attr_accessor :startline

    def initialize(ref, lines, startline, filename)
      @ref = ref
      @lines = lines
      @startline = startline
      @filename = filename
    end

    def data
      lines&.join("\n")
    end

    def name
      filename
    end

    def size
      data.length
    end

    def mode
      nil
    end
  end
end
