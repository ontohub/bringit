# frozen_string_literal: true

# Seed repo:
# 0e50ec4d3c7ce42ab74dda1d422cb2cbffe1e326 Merge branch 'lfs_pointers' into 'master'
# 33bcff41c232a11727ac6d660bd4b0c2ba86d63d Add valid and invalid lfs pointers
# 732401c65e924df81435deb12891ef570167d2e2 Update year in license file
# b0e52af38d7ea43cf41d8a6f2471351ac036d6c9 Empty commit
# 40f4a7a617393735a95a0bb67b08385bc1e7c66d Add ISO-8859-encoded file
# 66028349a123e695b589e09a36634d976edcc5e8 Merge branch 'add-comments-to-gitmodules' into 'master'
# de5714f34c4e34f1d50b9a61a2e6c9132fe2b5fd Add comments to the end of .gitmodules to test parsing
# fa1b1e6c004a68b7d8763b86455da9e6b23e36d6 Merge branch 'add-files' into 'master'
# eb49186cfa5c4338011f5f590fac11bd66c5c631 Add submodules nested deeper than the root
# 18d9c205d0d22fdf62bc2f899443b83aafbf941f Add executables and links files
# 5937ac0a7beb003549fc5fd26fc247adbce4a52e Add submodule from gitlab.com
# 570e7b2abdd848b95f2f578043fc23bd6f6fd24d Change some files
# 6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 More submodules
# d14d6c0abdd253381df51a723d58691b2ee1ab08 Remove ds_store files
# c1acaa58bbcbc3eafe538cb8274ba387047b69f8 Ignore DS files
# ae73cb07c9eeaf35924a10f713b364d32b2dd34f Binary file added
# 874797c3a73b60d2187ed6e2fcabd289ff75171e Ruby files modified
# 2f63565e7aac07bcdadb654e253078b727143ec4 Modified image
# 33f3729a45c02fc67d00adb1b8bca394b0e761d9 Image added
# 913c66a37b4a45b9769037c55c2d238bd0942d2e Files, encoding and much more
# cfe32cf61b73a0d5e9f13e774abde7ff789b1660 Add submodule
# 6d394385cf567f80a8fd85055db1ab4c5295806f Added contributing guide
# 1a0b36b3cdad1d2ee32457c102a8c0b7056fa863 Initial commit

module SeedRepo
  module BigCommit
    ID               = '913c66a37b4a45b9769037c55c2d238bd0942d2e'
    PARENT_ID        = 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660'
    MESSAGE          = 'Files, encoding and much more'
    AUTHOR_FULL_NAME = 'Dmitriy Zaporozhets'
    FILES_COUNT      = 2
  end

  module Commit
    ID               = '570e7b2abdd848b95f2f578043fc23bd6f6fd24d'
    PARENT_ID        = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
    MESSAGE          = "Change some files\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n"
    AUTHOR_FULL_NAME = 'Dmitriy Zaporozhets'
    FILES            = ['files/ruby/popen.rb', 'files/ruby/regex.rb'].freeze
    FILES_COUNT      = 2
    C_FILE_PATH      = 'files/ruby'
    C_FILES          = ['popen.rb', 'regex.rb', 'version_info.rb'].freeze
    BLOB_FILE        = %(%h3= @key.title\n%hr\n%pre= @key.key\n.actions\n  = link_to 'Remove', @key, :confirm => 'Are you sure?', :method => :delete, :class => \"btn danger delete-key\"\n\n\n)
    BLOB_FILE_PATH   = 'app/views/keys/show.html.haml'
  end

  module EmptyCommit
    ID               = 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9'
    PARENT_ID        = '40f4a7a617393735a95a0bb67b08385bc1e7c66d'
    MESSAGE          = 'Empty commit'
    AUTHOR_FULL_NAME = 'Rémy Coutable'
    FILES            = [].freeze
    FILES_COUNT      = FILES.count
  end

  module EncodingCommit
    ID               = '40f4a7a617393735a95a0bb67b08385bc1e7c66d'
    PARENT_ID        = '66028349a123e695b589e09a36634d976edcc5e8'
    MESSAGE          = 'Add ISO-8859-encoded file'
    AUTHOR_FULL_NAME = 'Stan Hu'
    FILES            = ['encoding/iso8859.txt'].freeze
    FILES_COUNT      = FILES.count
  end

  module FirstCommit
    ID               = '1a0b36b3cdad1d2ee32457c102a8c0b7056fa863'
    PARENT_ID        = nil
    MESSAGE          = 'Initial commit'
    AUTHOR_FULL_NAME = 'Dmitriy Zaporozhets'
    FILES            = ['LICENSE', '.gitignore', 'README.md'].freeze
    FILES_COUNT      = 3
  end

  module LastCommit
    ID               = '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6'
    PARENT_ID        = '0e1b353b348f8477bdbec1ef47087171c5032cd9'
    MESSAGE          = "Merge branch 'master' into 'master'"
    AUTHOR_FULL_NAME = 'Stan Hu'
    FILES            = ['bin/executable'].freeze
    FILES_COUNT      = FILES.count
  end

  module Repo
    HEAD = 'master'
    BRANCHES = %w(
      feature
      fix
      fix-blob-path
      fix-existing-submodule-dir
      fix-mode
      gitattributes
      gitattributes-updated
      master
      merge-test
    ).freeze
    TAGS = %w(v1.0.0 v1.1.0 v1.2.0 v1.2.1).freeze
  end

  module RubyBlob
    ID = '7e3e39ebb9b2bf433b4ad17313770fbe4051649c'
    NAME = 'popen.rb'
    CONTENT = <<~eos
      require 'fileutils'
      require 'open3'

      module Popen
        extend self

        def popen(cmd, path=nil)
          unless cmd.is_a?(Array)
            raise RuntimeError, "System commands must be given as an array of strings"
          end

          path ||= Dir.pwd

          vars = {
            "PWD" => path
          }

          options = {
            chdir: path
          }

          unless File.directory?(path)
            FileUtils.mkdir_p(path)
          end

          @cmd_output = ""
          @cmd_status = 0

          Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
            @cmd_output << stdout.read
            @cmd_output << stderr.read
            @cmd_status = wait_thr.value.exitstatus
          end

          return @cmd_output, @cmd_status
        end
      end
    eos
  end
end
