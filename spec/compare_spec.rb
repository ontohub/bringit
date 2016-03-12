require "spec_helper"

describe Gitlab::Git::Compare do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::Commit::ID) }

  describe :commits do
    subject do
      compare.commits.map(&:id)
    end

    it 'has 8 elements' do
      expect(subject.size).to eq(8)
    end
    it { is_expected.to include(SeedRepo::Commit::PARENT_ID) }
    it { is_expected.not_to include(SeedRepo::BigCommit::PARENT_ID) }
  end

  describe :diffs do
    subject do
      compare.diffs.map(&:new_path)
    end

    it 'has 10 elements' do
      expect(subject.size).to eq(10)
    end
    it { is_expected.to include('files/ruby/popen.rb') }
    it { is_expected.not_to include('LICENSE') }
  end

  describe 'non-existing refs' do
    let(:compare) { Gitlab::Git::Compare.new(repository, 'no-such-branch', '1234567890') }

    it { expect(compare.commits).to be_empty }
    it { expect(compare.diffs).to be_empty }
  end
end
