# frozen_string_literal: true

module Bringit
  class Compare
    attr_reader :head, :base, :straight

    def initialize(repository, base, head, straight = false)
      @repository = repository
      @straight = straight

      unless base && head
        @commits = []
        return
      end

      @base = Bringit::Commit.find(repository, base.try(:strip))
      @head = Bringit::Commit.find(repository, head.try(:strip))

      @commits = [] unless @base && @head
      @commits = [] if same
    end

    def same
      @base && @head && @base.id == @head.id
    end

    def commits
      return @commits if defined?(@commits)

      @commits = Bringit::Commit.between(@repository, @base.id, @head.id)
    end

    def diffs(options = {})
      return Bringit::DiffCollection.new([]) unless @head && @base

      paths = options.delete(:paths) || []
      options[:straight] = @straight
      Bringit::Diff.between(@repository, @head.id, @base.id, options, *paths)
    end
  end
end
