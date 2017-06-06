# Libraries
require 'ostruct'
require 'fileutils'
require 'linguist'
require 'active_support/core_ext/hash/compact'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/module/delegation'
require 'rugged'
require "charlock_holmes"

# Gitlab::Git
require_relative "gitlab_git/popen"
require_relative 'gitlab_git/encoding_helper'
require_relative 'gitlab_git/path_helper'
require_relative "gitlab_git/blame"
require_relative "gitlab_git/blob"
require_relative "gitlab_git/commit"
require_relative "gitlab_git/commit_stats"
require_relative "gitlab_git/compare"
require_relative "gitlab_git/diff"
require_relative "gitlab_git/diff_collection"
require_relative "gitlab_git/hook"
require_relative "gitlab_git/index"
require_relative "gitlab_git/rev_list"
require_relative "gitlab_git/repository"
require_relative "gitlab_git/tree"
require_relative "gitlab_git/blob_snippet"
require_relative "gitlab_git/ref"
require_relative "gitlab_git/branch"
require_relative "gitlab_git/tag"
require_relative "gitlab_git/util"
require_relative "gitlab_git/attributes"
require_relative "gitlab_git/version_info"
require_relative "gitlab_git/committing"
require_relative "gitlab_git/cloning"
require_relative "gitlab_git/pulling"
require_relative "gitlab_git/wrapper"

module Gitlab
  module Git
    BLANK_SHA = ('0' * 40).freeze
    TAG_REF_PREFIX = "refs/tags/".freeze
    BRANCH_REF_PREFIX = "refs/heads/".freeze

    class << self
      def ref_name(ref)
        ref.sub(/\Arefs\/(tags|heads)\//, '')
      end

      def branch_name(ref)
        ref = ref.to_s
        if self.branch_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def committer_hash(email:, name:)
        return if email.nil? || name.nil?

        {
          email: email,
          name: name,
          time: Time.now
        }
      end

      def tag_name(ref)
        ref = ref.to_s
        if self.tag_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def tag_ref?(ref)
        ref.start_with?(TAG_REF_PREFIX)
      end

      def branch_ref?(ref)
        ref.start_with?(BRANCH_REF_PREFIX)
      end

      def blank_ref?(ref)
        ref == BLANK_SHA
      end

      def version
        Gitlab::VersionInfo.parse(Gitlab::Popen.popen(%W(git --version)).first)
      end
    end
  end
end
