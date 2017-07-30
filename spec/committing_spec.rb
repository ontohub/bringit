# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Gitlab::Git::Committing) do
  context 'without errors' do
    subject { create(:git) }

    %w(master some_feature).each do |branch|
      it "has not yet created the #{branch} branch" do
        expect(subject.branch_exists?('master')).to be(false)
      end

      context "working on branch '#{branch}'" do
        if branch == 'master'
          let!(:additional_commit) { nil }
        else
          let!(:additional_commit) do
            subject.create_file(create(:git_commit_info,
                                       filepath: 'first_file'))
          end
          before { subject.create_branch(branch, 'master') }
        end
        let(:prior_commits) { additional_commit.nil? ? 0 : 1 }

        context 'adding a file' do
          let(:filepath) { generate(:filepath) }
          let!(:sha) do
            subject.create_file(create(:git_commit_info,
                                       filepath: filepath,
                                       branch: branch))
          end

          it 'creates a branch' do
            expect(subject.branch_exists?(branch)).to be(true)
          end

          it 'creates a new commit on the branch' do
            expect(subject.find_commits(ref: branch).size).
              to be(1 + prior_commits)
          end

          it 'sets the HEAD of the branch to the latest commit' do
            expect(subject.branch_sha(branch)).to eq(sha)
          end

          it 'creates the correct number of commits on that file' do
            expect(subject.log(ref: branch, path: filepath).map(&:id)).
              to eq([sha])
          end

          it 'creates the file' do
            expect(subject.blob(branch, filepath)).not_to be_nil
          end
        end

        context 'updating a file' do
          let(:filepath) { generate(:filepath) }
          let!(:sha1) do
            subject.create_file(create(:git_commit_info,
                                       filepath: filepath,
                                       branch: branch))
          end
          let!(:content1) { subject.blob(branch, filepath).data }
          let!(:sha2) do
            subject.update_file(create(:git_commit_info,
                                       filepath: filepath,
                                       branch: branch),
                                sha1)
          end
          let!(:content2) { subject.blob(branch, filepath).data }

          it 'sets the HEAD of the branch to the latest commit' do
            expect(subject.branch_sha(branch)).to eq(sha2)
          end

          it 'creates the correct number of commits on that file' do
            expect(subject.log(ref: branch, path: filepath).map(&:id)).
              to eq([sha2, sha1])
          end

          it 'changes the content' do
            expect(content2).not_to eq(content1)
          end
        end

        context 'updating a file while renaming' do
          let(:filepath1) { generate(:filepath) }
          let(:filepath2) { generate(:filepath) }
          let!(:content1) { generate(:content) }
          let!(:content2) { generate(:content) }
          let!(:sha1) do
            subject.create_file(create(:git_commit_info,
                                       filepath: filepath1,
                                       content: content1,
                                       branch: branch))
          end
          let!(:sha2) do
            commit_info = create(:git_commit_info,
                                 filepath: filepath2,
                                 content: content2,
                                 branch: branch)
            commit_info[:file].merge!(previous_path: filepath1)
            subject.update_file(commit_info, sha1)
          end

          it 'sets the HEAD of the branch to the latest commit' do
            expect(subject.branch_sha(branch)).to eq(sha2)
          end

          it 'creates the correct number of commits on that file' do
            expect(subject.log(ref: branch, path: filepath2).map(&:id)).
              to eq([sha2])
          end

          it 'removes the old file' do
            expect(subject.blob(branch, filepath1)).to be(nil)
          end

          it 'creates the new file' do
            expect(subject.blob(branch, filepath2)).not_to be(nil)
          end

          it 'changes the content' do
            expect(subject.blob(branch, filepath2).data).
              not_to eq(subject.blob(sha1, filepath1).data)
          end
        end

        context 'renaming a file' do
          let(:filepath1) { generate(:filepath) }
          let(:filepath2) { generate(:filepath) }
          let!(:sha1) do
            subject.create_file(create(:git_commit_info,
                                       filepath: filepath1,
                                       branch: branch))
          end
          let!(:sha2) do
            commit_info = create(:git_commit_info,
                                 filepath: filepath2,
                                 branch: branch)
            commit_info[:file].delete(:content)
            commit_info[:file].merge!(previous_path: filepath1)
            subject.rename_file(commit_info, sha1)
          end

          it 'sets the HEAD of the branch to the latest commit' do
            expect(subject.branch_sha(branch)).to eq(sha2)
          end

          it 'creates the correct number of commits on that file' do
            expect(subject.log(ref: branch, path: filepath2).map(&:id)).
              to eq([sha2])
          end

          it 'does not change the content' do
            expect(subject.blob(branch, filepath2).data).
              to eq(subject.blob(sha1, filepath1).data)
          end
        end

        context 'deleting a file' do
          let(:filepath) { generate(:filepath) }
          let!(:sha1) do
            subject.create_file(create(:git_commit_info,
                                       filepath: filepath,
                                       branch: branch))
          end
          let!(:sha2) do
            commit_info = create(:git_commit_info,
                                 filepath: filepath,
                                 branch: branch)
            commit_info[:file].delete(:content)
            subject.remove_file(commit_info, sha1)
          end

          it 'sets the HEAD of the branch to the latest commit' do
            expect(subject.branch_sha(branch)).to eq(sha2)
          end

          it 'creates the correct number of commits on that file' do
            expect(subject.log(ref: branch, path: filepath).map(&:id)).
              to eq([sha2, sha1])
          end

          it 'removes the file' do
            expect(subject.blob(branch, filepath)).to be_nil
          end
        end

        context 'creating a directory' do
          let!(:path) { 'dir/with/subdir' }
          let!(:sha) do
            options = create(:git_commit_info, branch: branch)
            options.delete(:file)
            subject.mkdir(path, options)
          end

          it 'creates a tree at the path' do
            expect(subject.tree(branch, path)).not_to be_nil
          end

          it 'creates a .gitkeep file in the directory' do
            expect(subject.blob(branch, File.join(path, '.gitkeep'))).
              not_to be_nil
          end
        end

        context 'making multiple changes at once' do
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

          before do
            info = create(:git_commit_info, branch: branch)
            info.delete(:file)
            info[:files] = [
              {path: new_files[0],
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
               action: :mkdir}
            ]
            subject.commit_multichange(info)
          end

          it 'performs the create action' do
            expect(subject.blob(branch, new_files[0]).data).
              to eq(new_contents[0])
          end

          it 'performs the rename action: the new filename exists' do
            expect(subject.blob(branch, new_files[1]).data).
              to eq(old_contents[1])
          end

          it 'performs the rename action: the old filename does not exist' do
            expect(subject.blob(branch, old_files[1])).to be_nil
          end

          it 'performs the non-renaming update action: new content correct' do
            expect(subject.blob(branch, old_files[2]).data).
              to eq(new_contents[2])
          end

          it 'performs the non-renaming update action: old content not there' do
            expect(subject.blob(branch, old_files[2]).data).
              not_to eq(old_contents[2])
          end

          it 'performs the renaming update action: new filename and content' do
            expect(subject.blob(branch, new_files[3]).data).
              to eq(new_contents[3])
          end

          it 'performs the renaming update action: the old content is gone' do
            expect(subject.blob(branch, new_files[3]).data).
              not_to eq(old_contents[3])
          end

          it 'performs the renaming update action: '\
            'the old filename does not exist' do
              expect(subject.blob(branch, old_files[3])).to be_nil
            end

          it 'performs the removing action' do
            expect(subject.blob(branch, old_files[4])).to be_nil
          end

          it 'performs the mkdir action: no blob exists at path' do
            expect(subject.blob(branch, new_files[5])).to be_nil
          end

          it 'performs the mkdir action: .gitkeep exists under path' do
            expect(subject.tree(branch, new_files[5]).first.path).
              to end_with('/.gitkeep')
          end

          it 'only adds one log entry' do
            expect(subject.log(ref: "#{branch}~").first.id).
              to eq(setup_commits.last)
          end
        end
      end
    end
  end

  context 'when the branch has changed in the meantime' do
    subject { create(:git) }
    let(:branch) { 'master' }
    let(:invalid_sha) { '0' * 40 }

    context 'adding a file' do
      before do
        subject.create_file(create(:git_commit_info,
                                   filepath: 'first_file',
                                   branch: branch))
      end

      let(:filepath) { generate(:filepath) }

      it 'raises an error' do
        expect do
          subject.create_file(create(:git_commit_info,
                                     filepath: filepath,
                                     branch: branch),
                              invalid_sha)
        end.to raise_error(Gitlab::Git::Committing::HeadChangedError)
      end
    end

    context 'updating a file' do
      let(:filepath) { generate(:filepath) }
      let!(:sha) do
        subject.create_file(create(:git_commit_info,
                                   filepath: filepath,
                                   branch: branch))
      end

      it 'raises an error' do
        expect do
          subject.update_file(create(:git_commit_info,
                                     filepath: filepath,
                                     branch: branch),
                              invalid_sha)
        end.to raise_error(Gitlab::Git::Committing::HeadChangedError)
      end
    end

    context 'renaming a file' do
      let(:filepath1) { generate(:filepath) }
      let(:filepath2) { generate(:filepath) }
      let!(:sha) do
        subject.create_file(create(:git_commit_info,
                                   filepath: filepath1,
                                   branch: branch))
      end
      let!(:content1) { subject.blob(branch, filepath1).data }

      it 'raises an error' do
        expect do
          commit_info = create(:git_commit_info,
                               filepath: filepath2,
                               branch: branch)
          commit_info[:file].merge!(previous_path: filepath1,
                                    content: content1)
          subject.rename_file(commit_info, invalid_sha)
        end.to raise_error(Gitlab::Git::Committing::HeadChangedError)
      end
    end

    context 'deleting a file' do
      let(:filepath) { generate(:filepath) }
      let!(:sha) do
        subject.create_file(create(:git_commit_info,
                                   filepath: filepath,
                                   branch: branch))
      end
      it 'raises an error' do
        expect do
          commit_info = create(:git_commit_info,
                               filepath: filepath,
                               branch: branch)
          commit_info[:file].delete(:content)
          subject.remove_file(commit_info, invalid_sha)
        end.to raise_error(Gitlab::Git::Committing::HeadChangedError)
      end
    end

    context 'creating a directory' do
      before do
        subject.create_file(create(:git_commit_info,
                                   filepath: 'first_file',
                                   branch: branch))
      end

      let!(:path) { 'dir/with/subdir' }

      it 'raises an error' do
        expect do
          options = create(:git_commit_info, branch: branch)
          options.delete(:file)
          subject.mkdir(path, options, invalid_sha)
        end.to raise_error(Gitlab::Git::Committing::HeadChangedError)
      end
    end
  end

  context 'when a file exists' do
    subject { create(:git) }
    let(:branch) { 'master' }

    context 'creating a directory' do
      let!(:path) { 'dir/with/subdir' }
      before do
        subject.create_file(create(:git_commit_info,
                                   filepath: path,
                                   branch: branch))
      end

      it 'raises an error' do
        expect do
          options = create(:git_commit_info, branch: branch)
          options.delete(:file)
          subject.mkdir(path, options)
        end.to raise_error(Gitlab::Git::Repository::InvalidBlobName,
                           /Directory already exists as a file/)
      end
    end
  end

  context 'when a directory exists' do
    subject { create(:git) }
    let(:branch) { 'master' }

    context 'creating a directory' do
      let!(:path) { 'dir/with/subdir' }
      before do
        subject.create_file(create(:git_commit_info,
                                   filepath: File.join(path, 'some_file'),
                                   branch: branch))
      end

      it 'raises an error' do
        expect do
          options = create(:git_commit_info, branch: branch)
          options.delete(:file)
          subject.mkdir(path, options)
        end.to raise_error(Gitlab::Git::Repository::InvalidBlobName,
                           /Directory already exists/)
      end
    end
  end
end
