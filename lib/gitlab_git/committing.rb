# frozen_string_literal: true

require_relative "committing/merge"

module Gitlab
  module Git
    # Methods for committing. Use all these methods only mutexed with the git
    # repository as the key.
    module Committing
      include Gitlab::Git::Committing::Merge

      class Error < StandardError; end
      class InvalidPathError < Error; end

      # This error is thrown when attempting to commit on a branch whose HEAD has
      # changed.
      class HeadChangedError < Error
        attr_reader :conflicts, :options
        def initialize(message, conflicts, options)
          super(message)
          @conflicts = conflicts
          @options = options
        end
      end

      # Create a file in repository and return commit sha
      #
      # options should contain the following structure:
      #   file: {
      #     content: 'Lorem ipsum...',
      #     path: 'documents/story.txt'
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',    # optional - default: 'master'
      #     update_ref: false    # optional - default: true
      #   }
      def create_file(options, previous_head_sha = nil)
        commit_multichange(convert_options(options, :create), previous_head_sha)
      end

      # Change the contents of a file in repository and return commit sha
      #
      # options should contain the following structure:
      #   file: {
      #     content: 'Lorem ipsum...',
      #     path: 'documents/story.txt'
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',    # optional - default: 'master'
      #     update_ref: false    # optional - default: true
      #   }
      def update_file(options, previous_head_sha = nil)
        commit_multichange(convert_options(options, :update), previous_head_sha)
      end

      # Change contents and path of a file in repository and return commit sha
      #
      # options should contain the following structure:
      #   file: {
      #     content: 'Lorem ipsum...',
      #     path: 'documents/story.txt',
      #     previous_path: 'documents/old_story.txt'
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',    # optional - default: 'master'
      #     update_ref: false    # optional - default: true
      #   }
      def rename_and_update_file(options, previous_head_sha = nil)
        commit_multichange(convert_options(options, :rename_and_update), previous_head_sha)
      end

      # Remove file from repository and return commit sha
      #
      # options should contain the following structure:
      #   file: {
      #     path: 'documents/story.txt'
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Remove FILENAME',
      #     branch: 'master'    # optional - default: 'master'
      #   }
      def remove_file(options, previous_head_sha = nil)
        commit_multichange(convert_options(options, :remove), previous_head_sha)
      end

      # Rename file from repository and return commit sha
      # This does not change the file content.
      #
      # options should contain the following structure:
      #   file: {
      #     previous_path: 'documents/old_story.txt'
      #     path: 'documents/story.txt'
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Rename FILENAME',
      #     branch: 'master'    # optional - default: 'master'
      #   }
      #
      def rename_file(options, previous_head_sha = nil)
        commit_multichange(convert_options(options, :rename), previous_head_sha)
      end

      # Create a new directory with a .gitkeep file. Creates
      # all required nested directories (i.e. mkdir -p behavior)
      #
      # options should contain the following structure:
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',    # optional - default: 'master'
      #     update_ref: false    # optional - default: true
      #   }
      def mkdir(path, options, previous_head_sha = nil)
        options[:file] = {path: path}
        commit_multichange(convert_options(options, :mkdir), previous_head_sha)
      end

      # Apply multiple file changes to the repository
      #
      # options should contain the following structure:
      #   files: {
      #     [{content: 'Lorem ipsum...',
      #       path: 'documents/story.txt',
      #       action: :create},
      #      {content: 'New Lorem ipsum...',
      #       path: 'documents/old_story',
      #       action: :update},
      #      {content: 'New Lorem ipsum...',
      #       previous_path: 'documents/really_old_story.txt',
      #       path: 'documents/old_story',
      #       action: :rename_and_update},
      #      {path: 'documents/obsolet_story.txt',
      #       action: :remove},
      #      {path: 'documents/old_story',
      #       previus_path: 'documents/really_old_story.txt',
      #       action: :rename},
      #      {path: 'documents/secret',
      #       action: :mkdir}
      #     ]
      #     }
      #   },
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now    # optional - default: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',    # optional - default: 'master'
      #     update_ref: false    # optional - default: true
      #   }
      def commit_multichange(options, previous_head_sha = nil)
        commit_with(options, previous_head_sha) do |index|
          options[:files].each do |file|
            file_options = {}
            file_options[:file_path] = file[:path] if file[:path]
            file_options[:content] = file[:content] if file[:content]
            file_options[:encoding] = file[:encoding] if file[:encoding]
            case file[:action]
            when :create
              index.create(file_options)
            when :rename
              file_options[:previous_path] = file[:previous_path]
              file_options[:content] ||=
                blob(options[:commit][:branch], file[:previous_path]).data
              index.move(file_options)
            when :update
              index.update(file_options)
            when :rename_and_update
              previous_path = file[:previous_path]
              file_options[:previous_path] = previous_path
              index.move(file_options)
            when :remove
              index.delete(file_options)
            when :mkdir
              index.create_dir(file_options)
            end
          end
        end
      end

      protected


      # Converts the options from a single change commit to a multi change
      # commit.
      def convert_options(options, action)
        converted = options.dup
        converted.delete(:file)
        converted[:files] = [options[:file].merge(action: action)]
        converted
      end

      def insert_defaults(options)
        options[:author][:time] ||= Time.now
        options[:committer][:time] ||= Time.now
        options[:commit][:branch] ||= 'master'
        options[:commit][:update_ref] = true if options[:commit][:update_ref].nil?
        normalize_ref(options)
        normalize_update_ref(options)
      end

      def normalize_ref(options)
        return if options[:commit][:branch].start_with?('refs/')
        options[:commit][:branch] = 'refs/heads/' + options[:commit][:branch]
      end

      def normalize_update_ref(options)
        options[:commit][:update_ref] =
          if options[:commit][:update_ref].nil?
            true
          else
            options[:commit][:update_ref]
          end
      end

      # This method does the actual committing. Use this mutexed with the git
      # repository as the key.
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/MethodLength
      def commit_with(options, previous_head_sha)
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/MethodLength
        insert_defaults(options)
        action, commit_sha = merge_if_needed(options, previous_head_sha)
        return commit_sha if action == :merge_commit_created

        index = Gitlab::Git::Index.new(gitlab)
        parents, last_commit = parents_and_last_commit(options)
        index.read_tree(last_commit.tree) if last_commit

        yield(index)
        create_commit(index, index.write_tree, options, parents)
      end

      def parents_and_last_commit(options)
        parents = []
        last_commit = nil
        unless empty?
          rugged_ref = rugged.references[options[:commit][:branch]]
          unless rugged_ref
            raise Gitlab::Git::Repository::InvalidRef, 'Invalid branch name'
          end
          last_commit = rugged_ref.target
          parents = [last_commit]
        end
        [parents, last_commit]
      end

      def create_commit(index, tree, options, parents)
        opts = {}
        opts[:tree] = tree
        opts[:author] = options[:author]
        opts[:committer] = options[:committer]
        opts[:message] = options[:commit][:message]
        opts[:parents] = parents
        if options[:commit][:update_ref]
          opts[:update_ref] = options[:commit][:branch]
        end

        Rugged::Commit.create(rugged, opts)
      end
    end
  end
end
