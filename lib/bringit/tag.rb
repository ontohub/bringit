# frozen_string_literal: true

module Bringit
  class Tag < Ref
    attr_reader :object_sha

    def self.find(repository, name)
      repository.tags.find { |tag| tag.name == name }
    end

    def initialize(repository, name, target, message = nil)
      super(repository, name, target)

      @message = message
    end

    def message
      encode! @message
    end
  end
end
