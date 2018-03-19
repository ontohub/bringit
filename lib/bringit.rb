# frozen_string_literal: true

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
require 'charlock_holmes'

# Bringit
require_relative 'bringit/popen'
require_relative 'bringit/encoding_helper'
require_relative 'bringit/path_helper'
require_relative 'bringit/blame'
require_relative 'bringit/blob'
require_relative 'bringit/commit'
require_relative 'bringit/commit_stats'
require_relative 'bringit/compare'
require_relative 'bringit/diff'
require_relative 'bringit/diff_collection'
require_relative 'bringit/hook'
require_relative 'bringit/index'
require_relative 'bringit/rev_list'
require_relative 'bringit/repository'
require_relative 'bringit/tree'
require_relative 'bringit/blob_snippet'
require_relative 'bringit/ref'
require_relative 'bringit/branch'
require_relative 'bringit/tag'
require_relative 'bringit/util'
require_relative 'bringit/attributes'
require_relative 'bringit/version_info'
require_relative 'bringit/committing'
require_relative 'bringit/cloning'
require_relative 'bringit/pulling'
require_relative 'bringit/wrapper'

module Bringit
  BLANK_SHA = ('0' * 40).freeze
  TAG_REF_PREFIX = 'refs/tags/'
  BRANCH_REF_PREFIX = 'refs/heads/'

  class << self
    def ref_name(ref)
      ref.sub(/\Arefs\/(tags|heads)\//, '')
    end

    def branch_name(ref)
      ref = ref.to_s
      ref_name(ref) if branch_ref?(ref)
    end

    def committer_hash(email:, name:)
      return if email.nil? || name.nil?

      {
        email: email,
        name: name,
        time: Time.now,
      }
    end

    def tag_name(ref)
      ref = ref.to_s
      ref_name(ref) if tag_ref?(ref)
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
      Bringit::VersionInfo.parse(Bringit::Popen.popen(%w(git --version)).first)
    end
  end
end
