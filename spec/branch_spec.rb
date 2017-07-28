require "spec_helper"

describe Gitlab::Git::Branch, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  subject { repository.branches }

  it { is_expected.to be_kind_of Array }

  describe '#size' do
    subject { super().size }
    it { is_expected.to eq(SeedRepo::Repo::BRANCHES.size) }
  end

  describe 'first branch' do
    let(:branch) { repository.branches.first }

    it { expect(branch.name).to eq(SeedRepo::Repo::BRANCHES.first) }
    it { expect(branch.dereferenced_target.sha).to eq("0b4bc9a49b562e85de7cc9e834518ea6828729b9") }
  end

  describe 'master branch' do
    let(:branch) do
      repository.branches.find { |branch| branch.name == 'master' }
    end

    it { expect(branch.dereferenced_target.sha).to eq(SeedRepo::LastCommit::ID) }
  end

  describe 'find' do
    RSpec.shared_examples 'the correctly found branch' do
      it 'points to the correct commit' do
        expect(found_branch.dereferenced_target.sha).
          to eq(base_branch.dereferenced_target.sha)
      end

      it 'has the correct name' do
        expect(found_branch.name).to eq(base_branch.name)
      end
    end

    context 'finds the first branch' do
      let(:base_branch) { repository.branches.first }
      let(:found_branch) { Gitlab::Git::Branch.find(repository, base_branch.name) }
      it_behaves_like 'the correctly found branch'
    end

    context 'finds the last branch' do
      let(:base_branch) { repository.branches.last }
      let(:found_branch) { Gitlab::Git::Branch.find(repository, base_branch.name) }
      it_behaves_like 'the correctly found branch'
    end

    it 'returns nil on a non-existant branch' do
      expect(Gitlab::Git::Branch.find(repository, 'non existant branch.')).
        to be(nil)
    end
  end

  it { expect(repository.branches.size).to eq(SeedRepo::Repo::BRANCHES.size) }
end
