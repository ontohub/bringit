require "spec_helper"

describe Gitlab::Git::Tag do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe 'first tag' do
    let(:tag) { repository.tags.first }

    it { expect(tag.name).to eq("v1.0.0") }
    it { expect(tag.target).to eq("f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8") }
    it { expect(tag.message).to eq("Release") }
  end

  describe 'last tag' do
    let(:tag) { repository.tags.last }

    it { expect(tag.name).to eq("v1.2.1") }
    it { expect(tag.target).to eq("2ac1f24e253e08135507d0830508febaaccf02ee") }
    it { expect(tag.message).to eq("Version 1.2.1") }
  end

  it { expect(repository.tags.size).to eq(SeedRepo::Repo::TAGS.size) }
end
