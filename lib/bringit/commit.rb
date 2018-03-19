# frozen_string_literal: true

# Bringit::Commit is a wrapper around native Rugged::Commit object
module Bringit
  class Commit
    include Bringit::EncodingHelper

    attr_reader :repository
    attr_accessor :raw_commit, :head, :refs

    SERIALIZE_KEYS = %i(
      id message parent_ids
      authored_date author_name author_email
      committed_date committer_name committer_email
    ).freeze

    attr_accessor *SERIALIZE_KEYS # rubocop:disable Lint/AmbiguousOperator

    delegate :tree, to: :raw_commit

    def ==(other)
      return false unless other.is_a?(Bringit::Commit)

      methods = %i(messageparent_idsauthored_dateauthor_name
                   author_email committed_date committer_name
                   committer_email)

      methods.all? do |method|
        send(method) == other.send(method)
      end
    end

    class << self
      # Get commits collection
      #
      # Ex.
      #   Commit.where(
      #     repo: repo,
      #     ref: 'master',
      #     path: 'app/models',
      #     limit: 10,
      #     offset: 5,
      #   )
      #
      def where(options)
        repo = options.delete(:repo)
        raise 'Bringit::Repository is required' unless repo.respond_to?(:log)

        repo.log(options).map { |c| decorate(c, repo) }
      end

      # Get single commit
      #
      # Ex.
      #   Commit.find(repo, '29eda46b')
      #
      #   Commit.find(repo, 'master')
      #
      def find(repo, commit_id = 'HEAD')
        return decorate(commit_id, repo) if commit_id.is_a?(Rugged::Commit)

        obj = if commit_id.is_a?(String)
                repo.rev_parse_target(commit_id)
              else
                Bringit::Ref.dereference_object(commit_id)
              end

        return nil unless obj.is_a?(Rugged::Commit)

        decorate(obj, repo)
      rescue Rugged::ReferenceError, Rugged::InvalidError, Rugged::ObjectError, Bringit::Repository::NoRepository
        nil
      end

      # Get last commit for HEAD
      #
      # Ex.
      #   Commit.last(repo)
      #
      def last(repo)
        find(repo)
      end

      # Get last commit for specified path and ref
      #
      # Ex.
      #   Commit.last_for_path(repo, '29eda46b', 'app/models')
      #
      #   Commit.last_for_path(repo, 'master', 'Gemfile')
      #
      def last_for_path(repo, ref, path = nil)
        where(
          repo: repo,
          ref: ref,
          path: path,
          limit: 1
        ).first
      end

      # Get commits between two revspecs
      # See also #repository.commits_between
      #
      # Ex.
      #   Commit.between(repo, '29eda46b', 'master')
      #
      def between(repo, base, head)
        repo.commits_between(base, head).map do |commit|
          decorate(commit, repo)
        end
      rescue Rugged::ReferenceError
        []
      end

      # Delegate Repository#find_commits
      def find_all(repo, options = {})
        repo.find_commits(options)
      end

      def decorate(commit, repository, ref = nil)
        Bringit::Commit.new(commit, repository, ref)
      end

      # Returns a diff object for the changes introduced by +rugged_commit+.
      # If +rugged_commit+ doesn't have a parent, then the diff is between
      # this commit and an empty repo.  See Repository#diff for the keys
      # allowed in the +options+ hash.
      def diff_from_parent(rugged_commit, options = {})
        options ||= {}
        break_rewrites = options[:break_rewrites]
        actual_options = Bringit::Diff.filter_diff_options(options)

        diff = if rugged_commit.parents.empty?
                 rugged_commit.diff(actual_options.merge(reverse: true))
               else
                 rugged_commit.parents[0].diff(rugged_commit, actual_options)
                end

        diff.find_similar!(break_rewrites: break_rewrites)
        diff
      end
    end

    def initialize(raw_commit, repository = nil, head = nil)
      raise 'Nil as raw commit passed' unless raw_commit

      if raw_commit.is_a?(Hash)
        init_from_hash(raw_commit)
      elsif raw_commit.is_a?(Rugged::Commit)
        init_from_rugged(raw_commit)
      else
        raise "Invalid raw commit type: #{raw_commit.class}"
      end

      @repository = repository
      @head = head
    end

    def sha
      id
    end

    def short_id(length = 10)
      id.to_s[0..length]
    end

    def safe_message
      @safe_message ||= message
    end

    def created_at
      committed_date
    end

    # Was this commit committed by a different person than the original author?
    def different_committer?
      author_name != committer_name || author_email != committer_email
    end

    def parent_id
      parent_ids.first
    end

    # Shows the diff between the commit's parent and the commit.
    #
    # Cuts out the header and stats from #to_patch and returns only the diff.
    def to_diff(options = {})
      diff_from_parent(options).patch
    end

    # Returns a diff object for the changes from this commit's first parent.
    # If there is no parent, then the diff is between this commit and an
    # empty repo.  See Repository#diff for keys allowed in the +options+
    # hash.
    def diff_from_parent(options = {})
      Commit.diff_from_parent(raw_commit, options)
    end

    def has_zero_stats?
      stats.total.zero?
    rescue StandardError
      true
    end

    def no_commit_message
      '--no commit message'
    end

    def to_hash
      serialize_keys.map.with_object({}) do |key, hash|
        hash[key] = send(key)
      end
    end

    def date
      committed_date
    end

    def diffs(options = {})
      Bringit::DiffCollection.new(diff_from_parent(options), options)
    end

    def parents
      raw_commit.parents.map { |c| Bringit::Commit.new(c, repository) }
    end

    def stats
      Bringit::CommitStats.new(self)
    end

    def to_patch(options = {})
      raw_commit.to_mbox(options)
    rescue Rugged::InvalidError => ex
      if ex.message.match?(/Commit \w+ is a merge commit/)
        'Patch format is not currently supported for merge commits.'
      end
    end

    # Get a collection of Rugged::Reference objects for this commit.
    #
    # Ex.
    #   commit.ref
    #
    def refs
      repository.refs_hash[id]
    end

    # Get a collection of Bringit::Ref (its subclasses) objects
    def references
      refs.map do |ref|
        if ref.name.match?(%r{\Arefs/heads/})
          Bringit::Branch.new(repository, ref.name, ref.target)
        elsif ref.name.match?(%r{\Arefs/tags/})
          message = nil

          if ref.target.is_a?(Rugged::Tag::Annotation)
            tag_message = ref.target.message

            message = tag_message.chomp if tag_message.respond_to?(:chomp)
          end

          Bringit::Tag.new(self, ref.name, ref.target, message)
        else
          Bringit::Ref.new(repository, ref.name, ref.target)
        end
      end
    end

    # Get ref names collection
    #
    # Ex.
    #   commit.ref_names
    #
    def ref_names
      repository.refs_hash[id].map do |ref|
        ref.name.sub(%r{^refs/(heads|remotes|tags)/}, '')
      end
    end

    def message
      encode! @message
    end

    def author_name
      encode! @author_name
    end

    def author_email
      encode! @author_email
    end

    def committer_name
      encode! @committer_name
    end

    def committer_email
      encode! @committer_email
    end

    private

    def init_from_hash(hash)
      raw_commit = hash.symbolize_keys

      serialize_keys.each do |key|
        send("#{key}=", raw_commit[key])
      end
    end

    def init_from_rugged(commit)
      author = commit.author
      committer = commit.committer

      @raw_commit = commit
      @id = commit.oid
      @message = commit.message
      @authored_date = author[:time]
      @committed_date = committer[:time]
      @author_name = author[:name]
      @author_email = author[:email]
      @committer_name = committer[:name]
      @committer_email = committer[:email]
      @parent_ids = commit.parents.map(&:oid)
    end

    def serialize_keys
      SERIALIZE_KEYS
    end
  end
end
