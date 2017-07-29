# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Gitlab::Git::Wrapper) do
  subject { FactoryGirl.create(:git) }
  let(:branch) { 'master' }
  let(:invalid_sha) { '0' * 40 }

  context 'create' do
    it 'fails if the path already exists' do
      path = tempdir.join('repo')
      path.mkpath
      expect { Gitlab::Git::Wrapper.create(path) }.to raise_error(Gitlab::Git::Error, /already exists/)
    end

    let!(:git) { Gitlab::Git::Wrapper.create('my_repo') }

    it 'is a Gitlab::Git::Wrapper' do
      expect(git).to be_a(Gitlab::Git::Wrapper)
    end

    it 'creates an existing git repository' do
      expect(git.repo_exists?).to be(true)
    end

    it 'creates a bare repository' do
      expect(git.bare?).to be(true)
    end

    it 'creates an empty repository' do
      expect(git.empty?).to be(true)
    end

    it 'creates a repository with no branches' do
      expect(git.branch_count).to eq(0)
    end

    it 'creates a directory at its path' do
      expect(File.directory?(git.path)).to be(true)
    end
  end

  context 'destroy' do
    before do
      # create the subject
      subject
      # and destroy it
      Gitlab::Git::Wrapper.destroy(subject.path)
    end

    it 'removes the directory of the git repository' do
      expect(File.exist?(subject.path)).to be(false)
    end
  end

  context 'path' do
    it 'is a Pathname' do
      expect(subject.path).to be_a(Pathname)
    end

    it 'is an absolute path' do
      expect(subject.path.absolute?).to be(true)
    end
  end

  context 'repo_exists?' do
    context 'when the repository exists' do
      let!(:git) { Gitlab::Git::Wrapper.create('my_repo') }

      it 'is true' do
        expect(git.repo_exists?).to be(true)
      end
    end

    context 'when the repository does not exist' do
      let!(:git) { Gitlab::Git::Wrapper.new('my_repo') }

      it 'is true' do
        expect(git.repo_exists?).to be(false)
      end
    end
  end

  context 'blob' do
    let(:filepath) { generate(:filepath) }
    let(:content) { 'some content' }
    let!(:sha) do
      subject.create_file(FactoryGirl.create(:git_commit_info,
                                             filepath: filepath,
                                             content: content,
                                             branch: branch))
    end

    it 'returns the blob by the branch' do
      expect(subject.blob(branch, filepath)).not_to be(nil)
    end

    it 'returns the same blob by the sha/branch' do
      expect(subject.blob(sha, filepath)).
        to match_blob(subject.blob(branch, filepath))
    end

    it 'returns nil if the path does not exist' do
      expect(subject.blob(sha, "#{filepath}.bad")).to be(nil)
    end

    it 'raises an error if the reference does not exist' do
      expect { subject.blob(invalid_sha, filepath) }.
        to raise_error(Rugged::ReferenceError)
    end

    it 'contains the content' do
      expect(subject.blob(sha, filepath).data).to eq(content)
    end

    it "contains the content's size" do
      expect(subject.blob(sha, filepath).size).to eq(content.size)
    end

    it 'contains the filepath' do
      expect(subject.blob(sha, filepath).path).to eq(filepath)
    end

    it 'contains the filename' do
      expect(subject.blob(sha, filepath).name).to eq(File.basename(filepath))
    end
  end

  context 'tree' do
    let(:filepath1) { generate(:filepath) }
    let(:filepath2) { generate(:filepath) }
    let(:content) { 'some content' }
    let!(:sha1) do
      subject.create_file(FactoryGirl.create(:git_commit_info,
                                             filepath: filepath1,
                                             content: content,
                                             branch: branch))
    end
    let!(:sha2) do
      subject.create_file(FactoryGirl.create(:git_commit_info,
                                             filepath: filepath2,
                                             content: content,
                                             branch: branch))
    end

    it 'returns the tree by the branch and nil' do
      expect(subject.tree(branch, nil)).not_to be(nil)
    end

    it 'returns the same tree by the branch and nil/root' do
      expect(subject.tree(branch, nil)).to match_tree(subject.tree(branch, '/'))
    end

    it 'returns the same tree by the sha/branch' do
      expect(subject.tree(sha2, nil)).to match_tree(subject.tree(branch, nil))
    end

    it 'returns an empty Array if no tree exists at the path' do
      expect(subject.tree(branch, filepath1)).to be_empty
    end

    it 'raises an error if the reference does not exist' do
      expect { subject.tree(invalid_sha, nil) }.
        to raise_error(Rugged::ReferenceError)
    end

    it 'lists the correct entries in the root @ HEAD' do
      expect(subject.tree(branch, nil).map(&:path)).
        to match_array([filepath1, filepath2].map { |f| File.dirname(f) })
    end

    it "lists the correct entries's paths in one directory @ HEAD" do
      expect(subject.tree(branch, File.dirname(filepath1)).map(&:path)).
        to match_array([filepath1])
    end

    it "lists the correct entries's names in one directory @ HEAD" do
      expect(subject.tree(branch, File.dirname(filepath1)).map(&:name)).
        to match_array([File.basename(filepath1)])
    end

    it 'lists the correct entries in the root @ HEAD~1' do
      expect(subject.tree(sha1, nil).map(&:path)).
        to match_array([File.dirname(filepath1)])
    end

    it 'lists the correct entries in one directory @ HEAD~1' do
      expect(subject.tree(sha1, File.dirname(filepath1)).map(&:path)).
        to match_array([filepath1])
    end
  end

  context 'commit' do
    let(:filepath) { generate(:filepath) }
    let(:content) { 'some content' }
    let(:author) { generate(:git_user) }
    let(:committer) { generate(:git_user) }
    let(:message) { generate(:commit_message) }
    let(:commit_info) do
      commit_info = FactoryGirl.create(:git_commit_info,
                                       filepath: filepath,
                                       content: content,
                                       branch: branch)
      commit_info[:author] = author
      commit_info[:committer] = committer
      commit_info[:commit][:message] = message
      commit_info
    end
    let!(:sha) { subject.create_file(commit_info) }

    it 'finds a commit by branch' do
      expect(subject.commit(branch)).to be_a(Gitlab::Git::Commit)
    end

    it 'finds the same commit by sha/branch' do
      expect(subject.commit(sha)).to match_commit(subject.commit(branch))
    end

    it 'returns nil if the reference does not exist' do
      expect(subject.commit(invalid_sha)).to be(nil)
    end

    it 'contains author name' do
      expect(subject.commit(branch).author_name).to eq(author[:name])
    end

    it 'contains author email' do
      expect(subject.commit(branch).author_email).to eq(author[:email])
    end

    it 'contains authored date' do
      expect(subject.commit(branch).authored_date).
        to match_git_date(author[:time])
    end

    it 'contains committer name' do
      expect(subject.commit(branch).committer_name).to eq(committer[:name])
    end

    it 'contains committer email' do
      expect(subject.commit(branch).committer_email).to eq(committer[:email])
    end

    it 'contains committed date' do
      expect(subject.commit(branch).committed_date).
        to match_git_date(committer[:time])
    end

    it 'contains the id' do
      expect(subject.commit(branch).id).to eq(sha)
    end

    it 'contains the message' do
      expect(subject.commit(branch).message).to eq(message)
    end
  end

  context 'path_exists?' do
    let(:filepath) { generate(:filepath) }
    let!(:sha) do
      subject.create_file(FactoryGirl.create(:git_commit_info,
                                             filepath: filepath,
                                             branch: branch))
    end

    it 'is true if the path points to a blob' do
      expect(subject.path_exists?(branch, filepath)).to be(true)
    end

    it 'is true if the path points to a blob @ sha' do
      expect(subject.path_exists?(sha, filepath)).to be(true)
    end

    it 'is true if the path points to a tree' do
      expect(subject.path_exists?(branch, File.dirname(filepath))).to be(true)
    end

    it 'is false if the path points to nothing' do
      expect(subject.path_exists?(branch, "#{filepath}.bad")).to be(false)
    end
  end

  context 'branch_sha' do
    let!(:sha) do
      subject.create_file(FactoryGirl.create(:git_commit_info, branch: branch))
    end

    it 'is the correct sha if the branch exists' do
      expect(subject.branch_sha(branch)).to eq(sha)
    end

    it 'is nil if the branch does not exist' do
      expect(subject.branch_sha("#{branch}-bad")).to be(nil)
    end
  end

  context 'default_branch' do
    context 'without branches' do
      it 'is nil' do
        expect(subject.default_branch).to be(nil)
      end
    end

    context 'with only one branch' do
      let(:default_branch) { 'main' }
      before do
        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = default_branch
        subject.create_file(commit_info)
      end

      it 'is that branch' do
        expect(subject.default_branch).to eq(default_branch)
      end
    end

    context 'with many branches' do
      let(:default_branch) { 'main' }
      let(:other_branch) { 'other' }

      before do
        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = default_branch
        subject.create_file(commit_info)

        subject.create_branch(other_branch, default_branch)

        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = other_branch
        subject.create_file(commit_info)
      end

      it 'is the first created branch' do
        expect(subject.default_branch).to eq(default_branch)
      end

      context 'setting the default branch' do
        before do
          subject.default_branch = other_branch
        end

        it 'sets the branch to the other one' do
          expect(subject.default_branch).to eq(other_branch)
        end
      end
    end

    context 'with many branches including master' do
      let(:default_branch) { 'main' }
      let(:other_branch) { 'other' }
      before do
        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = default_branch
        subject.create_file(commit_info)

        subject.create_branch(other_branch, default_branch)

        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = other_branch
        subject.create_file(commit_info)

        master_branch = 'master'
        subject.create_branch(master_branch, default_branch)

        commit_info = FactoryGirl.create(:git_commit_info)
        commit_info[:commit][:branch] = master_branch
        subject.create_file(commit_info)
      end

      it 'is the master' do
        expect(subject.default_branch).to eq('master')
      end

      context 'setting the default branch' do
        before do
          subject.default_branch = other_branch
        end

        it 'sets the branch to the other one' do
          expect(subject.default_branch).to eq(other_branch)
        end
      end
    end
  end

  context 'branches' do
    let!(:sha1) do
      subject.create_file(FactoryGirl.create(:git_commit_info, branch: branch))
    end

    let!(:sha2) do
      subject.create_file(FactoryGirl.create(:git_commit_info, branch: branch))
    end

    let(:name) { 'new_branch' }

    context 'create_branch' do
      RSpec.shared_examples 'a valid branch' do
        it 'points to the correct sha' do
          expect(subject.branch_sha(name)).to eq(sha)
        end
      end

      context 'by sha' do
        before { subject.create_branch(name, sha1) }
        it_behaves_like 'a valid branch' do
          let(:sha) { sha1 }
        end
      end

      context 'by branch' do
        before { subject.create_branch(name, branch) }
        it_behaves_like 'a valid branch' do
          let(:sha) { subject.branch_sha(branch) }
        end
      end

      context 'by revision' do
        before { subject.create_branch(name, "#{branch}~1") }
        it_behaves_like 'a valid branch' do
          let(:sha) { sha1 }
        end
      end

      context 'invalid name' do
        it 'fails' do
          expect { subject.create_branch("#{name}.", branch) }.
            to raise_error(Gitlab::Git::InvalidRefName)
        end

        it 'has the correct number of branches' do
          expect do
            begin
              subject.create_branch("#{name}.", branch)
            rescue Gitlab::Git::InvalidRefName
            end
          end.not_to(change { subject.branches.size })
        end
      end

      context 'duplicate' do
        before do
          subject.create_branch(name, sha2)
        end

        it 'fails' do
          expect { subject.create_branch(name, sha2) }.
            to raise_error(Gitlab::Git::Repository::InvalidRef,
                           'Branch new_branch already exists')
        end

        it 'has the correct number of branches' do
          # master and `name`
          expect(subject.branches.size).to eq(2)
        end
      end

      context 'bad revision' do
        let(:revision) { '0' * 40 }
        it 'fails' do
          expect { subject.create_branch(name, revision) }.
            to raise_error(Rugged::OdbError,
                           /object not found - no match for id/i)
        end
      end
    end

    context 'find_branch' do
      before do
        subject.create_branch("pre_#{name}", sha1)
        subject.create_branch(name, sha2)
      end

      let(:base_branch) { Gitlab::Git::Branch.find(subject, name) }
      let(:found_branch) { subject.find_branch(name) }

      it 'points to the correct commit' do
        expect(found_branch.dereferenced_target.sha).
          to eq(base_branch.dereferenced_target.sha)
      end

      it 'has the correct name' do
        expect(found_branch.name).to eq(base_branch.name)
      end
    end

    context 'rm_branch' do
      before do
        subject.create_branch("pre_#{name}", sha1)
        subject.create_branch(name, sha2)
      end

      context 'with an existing branch' do
        before { subject.rm_branch(name) }

        it 'the deleted branch cannot be found' do
          expect(Gitlab::Git::Branch.find(subject, name)).to be(nil)
        end

        it 'the other tag can still be found' do
          expect(Gitlab::Git::Branch.find(subject, "pre_#{name}")).
            not_to be(nil)
        end

        it 'reduces the number of branches' do
          # master and `name`
          expect(subject.branches.size).to eq(2)
        end
      end

      context 'with an inexistant branch' do
        before { subject.rm_branch('inexistant.') }

        it 'does not reduce the number of branches' do
          # master, pre_`name` and `name`
          expect(subject.branches.size).to eq(3)
        end
      end
    end
  end

  context 'tags' do
    let!(:sha1) do
      subject.create_file(FactoryGirl.create(:git_commit_info, branch: branch))
    end

    let!(:sha2) do
      subject.create_file(FactoryGirl.create(:git_commit_info, branch: branch))
    end

    let(:name) { 'new_tag' }

    context 'create_tag' do
      let(:created_tag) do
        subject.tags.select { |tag| tag.name == name }.first
      end

      RSpec.shared_examples 'a valid tag' do
        it 'points to the correct sha' do
          expect(created_tag.dereferenced_target.id).to eq(sha)
        end

        it 'has the correct name' do
          expect(created_tag.name).to eq(name)
        end
      end

      context 'by sha' do
        before { subject.create_tag(name, sha1) }

        it_behaves_like 'a valid tag' do
          let(:sha) { sha1 }
        end

        it 'is not annotated' do
          expect(created_tag.message).to be(nil)
        end

        it 'has the correct number of tags' do
          expect(subject.tags.size).to eq(1)
        end
      end

      context 'by branch' do
        before { subject.create_tag(name, branch) }

        it_behaves_like 'a valid tag' do
          let(:sha) { sha2 }
        end

        it 'has the correct number of tags' do
          expect(subject.tags.size).to eq(1)
        end
      end

      context 'by rev' do
        before { subject.create_tag(name, "#{branch}~1") }

        it_behaves_like 'a valid tag' do
          let(:sha) { sha1 }
        end

        it 'has the correct number of tags' do
          expect(subject.tags.size).to eq(1)
        end
      end

      context 'invalid name' do
        it 'fails' do
          expect { subject.create_tag("#{name}.", branch) }.
            to raise_error(Gitlab::Git::InvalidRefName)
        end

        it 'has the correct number of tags' do
          expect do
            begin
              subject.create_tag("#{name}.", branch)
            rescue Gitlab::Git::InvalidRefName
            end
          end.not_to(change { subject.tags.size })
        end
      end

      context 'duplicate' do
        before do
          subject.create_tag(name, branch)
        end

        it 'fails' do
          expect { subject.create_tag(name, branch) }.
            to raise_error(Gitlab::Git::Repository::InvalidRef,
                           'Tag already exists')
        end

        it 'has the correct number of tags' do
          expect(subject.tags.size).to eq(1)
        end
      end

      context 'bad revision' do
        let(:revision) { '0' * 40 }
        it 'fails' do
          expect { subject.create_tag(name, revision) }.
            to raise_error(Rugged::OdbError,
                           /object not found - no match for id/i)
        end
      end

      context 'with message' do
        let(:message) { "test tag message\nwith many\nlines\n" }
        let(:tagger) do
          FactoryGirl.create(:git_commit_info)[:author]
        end
        before do
          subject.create_tag(name, branch, {message: message, tagger: tagger})
        end

        it_behaves_like 'a valid tag' do
          let(:sha) { subject.branch_sha(branch) }
        end

        it 'has an annotation' do
          expect(created_tag.message).to eq(message.strip)
        end
      end
    end

    context 'find_tag' do
      before do
        subject.create_tag("pre_#{name}", sha1)
        subject.create_tag(name, sha2)
      end

      let(:base_tag) { Gitlab::Git::Tag.find(subject, name) }
      let(:found_tag) { subject.find_tag(name) }

      it 'points to the correct commit' do
        expect(found_tag.dereferenced_target.id).
          to eq(base_tag.dereferenced_target.id)
      end

      it 'has the correct name' do
        expect(found_tag.name).to eq(base_tag.name)
      end

      it 'has the correct message' do
        expect(found_tag.message).to eq(base_tag.message)
      end
    end

    context 'rm_tag' do
      before do
        subject.create_tag("pre_#{name}", sha1)
        subject.create_tag(name, sha2)
      end

      context 'with an existing tag' do
        before { subject.rm_tag(name) }

        it 'the deleted tag cannot be found' do
          expect(Gitlab::Git::Tag.find(subject, name)).to be(nil)
        end

        it 'the other tag can still be found' do
          expect(Gitlab::Git::Tag.find(subject, "pre_#{name}")).
            not_to be(nil)
        end

        it 'reduces the number of tags' do
          expect(subject.tags.size).to eq(1)
        end
      end

      context 'with an inexistant tag' do
        before { subject.rm_tag('inexistant.') }

        it 'does not reduce the number of tags' do
          expect(subject.tags.size).to eq(2)
        end
      end
    end
  end

  context 'ls_files' do
    let(:filepaths) { (1..5).map { generate(:filepath) } }
    before do
      filepaths.each do |filepath|
        subject.create_file(FactoryGirl.create(:git_commit_info, filepath: filepath))
      end
    end

    it 'returns the filepaths' do
      expect(subject.ls_files(branch)).to match_array(filepaths)
    end
  end

  context 'diff' do
    let(:num_setup_commits) { 6 }
    let!(:file_range) { (0 .. num_setup_commits - 1) }
    let!(:old_files) { file_range.map { generate(:filepath) } }
    let!(:old_contents) { file_range.map { generate(:content) } }
    let!(:setup_commits) do
      file_range.map do |i|
        subject.create_file(create(:git_commit_info,
                                   filepath: old_files[i],
                                   content: old_contents[i],
                                   branch: branch))
      end
    end
    let!(:new_files) { file_range.map { generate(:filepath) } }
    let!(:new_contents) { file_range.map { generate(:content) } }
    let(:commit_info_files) do
      [{path: new_files[0],
        content: new_contents[0],
        action: :create},

       {path: new_files[1],
        previous_path: old_files[1],
        action: :rename},

       {path: old_files[2],
        content: new_contents[2],
        action: :update},

       {path: new_files[3],
        content: new_contents[3],
        previous_path: old_files[3],
        action: :update},

       {path: old_files[4],
        action: :remove},

       {path: new_files[5],
        action: :mkdir}]
    end

    before do
      info = create(:git_commit_info, branch: branch)
      info.delete(:file)
      info[:files] = commit_info_files
      subject.commit_multichange(info)
    end

    context 'with nil revisions' do
      it "is empty if both revisions are nil" do
        expect(subject.diff(nil, nil)).to be_empty
      end

      it "has all but the last commit if the 'from' argument is nil" do
        expect(subject.diff(nil, setup_commits.last).map(&:new_path)).
          to match_array(old_files)
      end

      it "only has the first commit if the 'to' argument is nil" do
        expect(subject.diff(setup_commits.first, nil).map(&:new_path)).
          to match_array(old_files[0])
      end
    end

    context 'with bad revisions' do
      it "raises an error if the 'from' argument is bad" do
        expect { subject.diff('0' * 40, setup_commits.last) }.
          to raise_error(Rugged::ReferenceError)
      end

      it "raises an error if the 'to' argument is bad" do
        expect { subject.diff(setup_commits.first, '0' * 40) }.
          to raise_error(Rugged::ReferenceError)
      end
    end

    context 'diff' do
      context 'without paths' do
        let(:diffs) { subject.diff(setup_commits.first, setup_commits.last) }

        it 'is of the correct class' do
          expect(diffs).to be_a(Gitlab::Git::DiffCollection)
        end

        it 'has elements of the correct class' do
          expect(diffs.first).to be_a(Gitlab::Git::Diff)
        end

        it 'has the correct number of diffs (changed files)' do
          expect(diffs.count).to eq(setup_commits.size - 1)
        end
      end

      context 'with paths' do
        context 'from root' do
          let(:diffs) do
            subject.diff(nil, setup_commits.last, {}, *(old_files[0..3]))
          end

          it 'is of the correct class' do
            expect(diffs).to be_a(Gitlab::Git::DiffCollection)
          end

          it 'has elements of the correct class' do
            expect(diffs.first).to be_a(Gitlab::Git::Diff)
          end

          it 'has the correct number of diffs (changed files)' do
            # The first file is not in the diff, because that one is not changed
            # in this range.  The other three files are in the diff.
            expect(diffs.count).to eq(4)
          end
        end

        context 'from a commit' do
          let(:diffs) do
            subject.diff(setup_commits.first, setup_commits.last, {},
                         *(old_files[0..3]))
          end

          it 'is of the correct class' do
            expect(diffs).to be_a(Gitlab::Git::DiffCollection)
          end

          it 'has elements of the correct class' do
            expect(diffs.first).to be_a(Gitlab::Git::Diff)
          end

          it 'has the correct number of diffs (changed files)' do
            # The first file is not in the diff, because that one is not changed
            # in this range.  The other three files are in the diff.
            expect(diffs.count).to eq(3)
          end
        end
      end
    end

    context 'diff_from_parent' do
      context 'without a ref' do
        let(:diffs) { subject.diff_from_parent }

        it 'is of the correct class' do
          expect(diffs).to be_a(Gitlab::Git::DiffCollection)
        end

        it 'has elements of the correct class' do
          expect(diffs.first).to be_a(Gitlab::Git::Diff)
        end

        it 'has the correct number of diffs (changed files)' do
          # one additional diff because the update/rename combination is
          # recognized as delete + create due to a too large content change.
          expect(diffs.count).to eq(commit_info_files.size + 1)
        end
      end

      context 'with a ref' do
        let(:ref) { "#{subject.default_branch}~1" }
        let(:diffs) { subject.diff_from_parent(ref) }

        it 'is of the correct class' do
          expect(diffs).to be_a(Gitlab::Git::DiffCollection)
        end

        it 'has elements of the correct class' do
          expect(diffs.first).to be_a(Gitlab::Git::Diff)
        end

        it 'has the correct number of diffs (changed files)' do
          expect(diffs.count).to eq(1)
        end
      end
    end
  end
end
