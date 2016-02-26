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

        paths = options.delete(:paths) || []
        Gitlab::Git::Diff.between(@repository, @head.id, @base.id, options, *paths)
      end

      # Check if diff is empty because it is actually empty
      # and not because its impossible to get it
      def empty_diff?
        # It is OK to use 'all_diffs: true' because "any?" stops once it finds one.
        !diffs(all_diffs: true).any?
      end
    end
  end
end
