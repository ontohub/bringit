# frozen_string_literal: true

module Gitlab
  module Git
    module Committing
      # Methods for merging a commit into another if the previous_head_sha is
      # an ancestor of the current HEAD of a branch.
      module Merge
        def merge_if_needed(options, previous_head_sha)
          return [:noop, nil] unless diverged?(options, previous_head_sha)

          commit_sha = merge(options, previous_head_sha)
          return [:merge_commit_created, commit_sha]
        end

        def diverged?(options, previous_head_sha)
          !previous_head_sha.nil? &&
            branch_sha(options[:commit][:branch]) != previous_head_sha
        end

        def merge(options, previous_head_sha)
          user_commit = create_user_commit(options, previous_head_sha)
          base_commit = commit(options[:commit][:branch]).raw_commit

          index = rugged.merge_commits(base_commit, user_commit)

          if index.conflicts?
            enriched_conflicts = add_merge_data(options, index)
            raise_head_changed_error(enriched_conflicts, options)
          end
          tree_id = index.write_tree(rugged)
          found_conflicts = conflicts(options, base_commit, user_commit)
          if found_conflicts.any?
            raise_head_changed_error(found_conflicts, options)
          end
          create_merging_commit(base_commit, index, tree_id, options)
        end

        def add_merge_data(options, index)
          our_label = options[:commit][:branch].sub(%r{\Arefs/heads/}, '')
          index.conflicts.map do |conflict|
            if conflict[:ancestor] && conflict[:ours] && conflict[:theirs]
              conflict[:merge_info] =
                index.merge_file(conflict[:ours][:path],
                                 ancestor_label: 'parent',
                                 our_label: our_label,
                                 their_label: options[:commit][:message])
            else
              conflict[:merge_info] = nil
            end
            conflict
          end
        end

        def conflicts(options, base_commit, user_commit)
          options[:files].map do |file|
            case file[:action]
            when :update
              conflict_on_update(base_commit, user_commit, file[:path])
            when :rename_and_update
              conflict_on_update(base_commit, user_commit, file[:previous_path])
            end
          end.compact
        end

        def conflict_on_update(base_commit, user_commit, path)
          base_blob = blob(base_commit.oid, path)
          return nil unless base_blob.nil?

          ancestor_blob = blob(base_commit.parents.first.oid, path)
          user_blob = blob(user_commit.oid, path)
          result = {merge_info: nil, ours: nil}
          result[:ancestor] = conflict_hash(ancestor_blob, 1) if ancestor_blob
          result[:theirs] = conflict_hash(user_blob, 3) if user_blob
          result
        end

        def conflict_hash(blob_object, stage)
          {path: blob_object.path,
           oid: blob_object.id,
           dev: 0,
           ino: 0,
           mode: blob_object.mode.to_i(8),
           gid: 0,
           uid: 0,
           file_size: 0,
           valid: false,
           stage: stage,
           ctime: Time.at(0),
           mtime: Time.at(0)}
        end

        def create_user_commit(options, previous_head_sha)
          with_temp_user_reference(options, previous_head_sha) do |reference|
            new_options = options.dup
            new_options[:commit] = options[:commit].dup
            new_options[:commit][:branch] = reference.name
            new_options[:commit][:update_ref] = false
            commit_sha = commit_multichange(new_options)
            rugged.lookup(commit_sha)
          end
        end

        def with_temp_user_reference(options, previous_head_sha)
          refname = "#{Time.now.to_f.to_s.tr('.', '')}_#{SecureRandom.hex(20)}"
          full_refname = "refs/merges/user/#{refname}"
          reference = rugged.references.create(full_refname, previous_head_sha)
          yield(reference)
        ensure
          rugged.references.delete(reference)
        end

        def create_merging_commit(parent_commit, index, tree_id, options)
          parents = [parent_commit.oid]
          create_commit(index, tree_id, options, parents)
        end

        def raise_head_changed_error(conflicts, options)
          message = <<MESSAGE
The branch has changed since editing and cannot be merged automatically.
MESSAGE
          raise HeadChangedError.new(message, conflicts, options)
        end
      end
    end
  end
end
