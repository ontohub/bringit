# frozen_string_literal: true

module Gitlab
  module Git
    # This class encapsulates all git related functionality for convenience.
    class Wrapper
      extend ::Gitlab::Git::Cloning::ClassMethods
      include ::Gitlab::Git::Committing
      include ::Gitlab::Git::Pulling

      class ::Gitlab::Git::Error < ::StandardError; end
      class ::Gitlab::Git::InvalidRefName < ::Gitlab::Git::Error; end

      attr_reader :gitlab
      delegate :bare?, :branches, :branch_count, :branch_exists?, :branch_names,
               :commit_count, :diff, :find_commits, :empty?, :ls_files,
               :rugged, :tag_names, :tags, to: :gitlab

      def self.create(path)
        raise Error, "Path #{path} already exists." if Pathname.new(path).exist?
        FileUtils.mkdir_p(File.dirname(path))
        Rugged::Repository.init_at(path.to_s, :bare)
        new(path)
      end

      def self.destroy(path)
        new(path.to_s).gitlab.repo_exists? && FileUtils.rm_rf(path)
      end

      def initialize(path)
        @gitlab = Gitlab::Git::Repository.new(path.to_s)
      end

      def repo_exists?
        gitlab.repo_exists?
      rescue Gitlab::Git::Repository::NoRepository
        false
      end

      def path
        Pathname.new(gitlab.
                     instance_variable_get(:@attributes).
                     instance_variable_get(:@path))
      end

      # Query for a blob
      def blob(ref, path)
        Gitlab::Git::Blob.find(gitlab, ref, path)
      end

      # Query for a tree
      def tree(ref, path)
        Gitlab::Git::Tree.where(gitlab, ref, path)
      end

      def commit(ref)
        Gitlab::Git::Commit.find(gitlab, ref)
      end

      # Query for a tree
      def path_exists?(ref, path)
        !blob(ref, path).nil? || tree(ref, path).any?
      end

      def branch_sha(name)
        gitlab.find_branch(name)&.dereferenced_target&.sha
      end

      def default_branch
        gitlab.discover_default_branch
      end

      def default_branch=(name)
        ref = "refs/heads/#{name}" unless name.start_with?('refs/heads/')
        rugged.head = ref
      end

      # Create a branch with name +name+ at the reference +ref+.
      def create_branch(name, revision)
        raise_invalid_name_error(name) unless Ref.name_valid?(name)
        gitlab.create_branch(name, revision)
      end

      def find_branch(name)
        Gitlab::Git::Branch.find(self, name)
      end

      def rm_branch(name)
        rugged.branches.delete(name) if find_branch(name)
      end

      # If +annotation+ is not +nil+, it will cause the creation of an
      # annotated tag object.  +annotation+ has to contain the following key
      # value pairs:
      # :tagger ::
      #   An optional Hash containing a git signature. Defaults to the signature
      #   from the configuration if only `:message` is given. Will cause the
      #   creation of an annotated tag object if present.
      # :message ::
      #   An optional string containing the message for the new tag.
      def create_tag(name, revision, annotation = nil)
        raise_invalid_name_error(name) unless Ref.name_valid?(name)
        rugged.tags.create(name, revision, annotation)
        find_tag(name)
      rescue Rugged::TagError => error
        raise Gitlab::Git::Repository::InvalidRef, error.message
      end

      def find_tag(name)
        Gitlab::Git::Tag.find(self, name)
      end

      def rm_tag(name)
        rugged.tags.delete(name) if find_tag(name)
      end

      def diff_from_parent(ref = default_branch, options = {})
        Commit.find(gitlab, ref).diffs(options)
      end

      def log(*args)
        gitlab.log(*args).map do |commit|
          Gitlab::Git::Commit.new(commit, gitlab)
        end
      end

      protected

      def raise_invalid_name_error(name)
        url = 'https://git-scm.com/docs/git-check-ref-format'
        raise ::Gitlab::Git::InvalidRefName,
          %(Name "#{name}" is invalid. See #{url} for a valid format.)
      end
    end
  end
end
