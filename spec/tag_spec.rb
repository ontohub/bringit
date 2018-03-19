# frozen_string_literal: true

require 'spec_helper'

describe Bringit::Tag, seed_helper: true do
  let(:repository) { Bringit::Repository.new(TEST_REPO_PATH) }

  describe 'first tag' do
    let(:tag) { repository.tags.first }

    it { expect(tag.name).to eq('v1.0.0') }
    it { expect(tag.target).to eq('f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8') }
    it { expect(tag.dereferenced_target.sha).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    it { expect(tag.message).to eq('Release') }
  end

  describe 'last tag' do
    let(:tag) { repository.tags.last }

    it { expect(tag.name).to eq('v1.2.1') }
    it { expect(tag.target).to eq('2ac1f24e253e08135507d0830508febaaccf02ee') }
    it { expect(tag.dereferenced_target.sha).to eq('fa1b1e6c004a68b7d8763b86455da9e6b23e36d6') }
    it { expect(tag.message).to eq('Version 1.2.1') }
  end

  describe 'find' do
    RSpec.shared_examples 'the correctly found tag' do
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

    context 'finds the first tag' do
      let(:base_tag) { repository.tags.first }
      let(:found_tag) { Bringit::Tag.find(repository, base_tag.name) }
      it_behaves_like 'the correctly found tag'
    end

    context 'finds the last tag' do
      let(:base_tag) { repository.tags.last }
      let(:found_tag) { Bringit::Tag.find(repository, base_tag.name) }
      it_behaves_like 'the correctly found tag'
    end

    it 'returns nil on a non-existant tag' do
      # This name cannot be a tag. See
      # https://git-scm.com/docs/git-check-ref-format:
      # 7. They cannot end with a dot `.`.
      expect(Bringit::Tag.find(repository, 'non existant tag.')).to be(nil)
    end
  end

  it { expect(repository.tags.size).to eq(SeedRepo::Repo::TAGS.size) }
end
