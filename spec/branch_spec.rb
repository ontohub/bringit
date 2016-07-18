require "spec_helper"

describe Gitlab::Git::Branch do
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
    it { expect(branch.target.sha).to eq("0b4bc9a49b562e85de7cc9e834518ea6828729b9") }
  end

  describe 'last branch' do
    let(:branch) { repository.branches.last }

    it { expect(branch.name).to eq(SeedRepo::Repo::BRANCHES.last) }
    it { expect(branch.target.sha).to eq(SeedRepo::LastCommit::ID) }
  end

  it { expect(repository.branches.size).to eq(SeedRepo::Repo::BRANCHES.size) }
end
