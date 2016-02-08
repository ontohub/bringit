module Gitlab
  module Git
    class Compare
      attr_reader :commits, :same, :head, :base

      def initialize(repository, base, head)
        @commits= []
        @same = false
        @repository = repository

        return unless base && head

        @base = Gitlab::Git::Commit.find(repository, base.try(:strip))
        @head = Gitlab::Git::Commit.find(repository, head.try(:strip))

        return unless @base && @head

        if @base.id == @head.id
          @same = true
          return
        end

        @commits = Gitlab::Git::Commit.between(repository, @base.id, @head.id)
      end

      def diffs(options = {})
        unless @head && @base
          return Gitlab::Git::DiffCollection.empty
        end

        # Try to collect diff only if diffs is empty
        # Otherwise return cached version
        if @diffs.nil?
            paths = options.delete(:paths) || []
            @diffs = Gitlab::Git::Diff.between(@repository, @head.id, @base.id,
              options, *paths)
        end

        @diffs
      end

      # Check if diff is empty because it is actually empty
      # and not because its impossible to get it
      def empty_diff?
        diffs.to_a.empty?
      end
    end
  end
end
