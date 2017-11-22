# frozen_string_literal: true

module Bringit
  # This class encapsulates all git related functionality for convenience.
  class Wrapper
    extend ::Bringit::Cloning::ClassMethods
    include ::Bringit::Committing
    include ::Bringit::Pulling

    class ::Bringit::Error < ::StandardError; end
    class ::Bringit::InvalidRefName < ::Bringit::Error; end

    attr_reader :bringit
    delegate :bare?, :branches, :branch_count, :branch_exists?, :branch_names,
              :commit_count, :diff, :find_commits, :empty?, :ls_files,
              :rugged, :tag_names, :tags, to: :bringit

    def self.create(path)
      raise Error, "Path #{path} already exists." if Pathname.new(path).exist?
      FileUtils.mkdir_p(File.dirname(path))
      Rugged::Repository.init_at(path.to_s, :bare)
      new(path)
    end

    def self.destroy(path)
      new(path.to_s).bringit.repo_exists? && FileUtils.rm_rf(path)
    end

    def initialize(path)
      @bringit = Bringit::Repository.new(path.to_s)
    end

    def repo_exists?
      bringit.repo_exists?
    rescue Bringit::Repository::NoRepository
      false
    end

    def path
      Pathname.new(bringit.
                    instance_variable_get(:@attributes).
                    instance_variable_get(:@path))
    end

    # Query for a blob
    def blob(ref, path)
      Bringit::Blob.find(bringit, ref, path)
    end

    # Query for a tree
    def tree(ref, path)
      Bringit::Tree.where(bringit, ref, path)
    end

    def commit(ref)
      Bringit::Commit.find(bringit, ref)
    end

    # Query for a tree
    def path_exists?(ref, path)
      !blob(ref, path).nil? || tree(ref, path).any?
    end

    def branch_sha(name)
      bringit.find_branch(name)&.dereferenced_target&.sha
    end

    def default_branch
      bringit.discover_default_branch
    end

    def default_branch=(name)
      ref = "refs/heads/#{name}" unless name.start_with?('refs/heads/')
      rugged.head = ref
    end

    # Create a branch with name +name+ at the reference +ref+.
    def create_branch(name, revision)
      raise_invalid_name_error(name) unless Ref.name_valid?(name)
      bringit.create_branch(name, revision)
    end

    def find_branch(name)
      Bringit::Branch.find(self, name)
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
      raise Bringit::Repository::InvalidRef, error.message
    end

    def find_tag(name)
      Bringit::Tag.find(self, name)
    end

    def rm_tag(name)
      rugged.tags.delete(name) if find_tag(name)
    end

    def diff_from_parent(ref = default_branch, options = {})
      Commit.find(bringit, ref).diffs(options)
    end

    def log(options)
      result = bringit.log(options)
      return result if options[:only_commit_sha]
      result.map do |commit|
        Bringit::Commit.new(commit, bringit)
      end
    end

    protected

    def raise_invalid_name_error(name)
      url = 'https://git-scm.com/docs/git-check-ref-format'
      raise ::Bringit::InvalidRefName,
        %(Name "#{name}" is invalid. See #{url} for a valid format.)
    end
  end
end
