
# frozen_string_literal: true

require 'spec_helper'

describe Bringit::Blame, seed_helper: true do
  let(:repository) { Bringit::Repository.new(TEST_REPO_PATH) }
  let(:blame) do
    Bringit::Blame.new(repository, SeedRepo::Commit::ID, 'CONTRIBUTING.md')
  end

  context 'each count' do
    it do
      data = []
      blame.each do |commit, line|
        data << {
          commit: commit,
          line: line,
        }
      end

      expect(data.size).to eq(95)
      expect(data.first[:commit]).to be_kind_of(Bringit::Commit)
      expect(data.first[:line]).to eq('# Contribute to GitLab')
    end
  end

  context 'ISO-8859 encoding' do
    let(:blame) do
      Bringit::Blame.new(repository, SeedRepo::EncodingCommit::ID, 'encoding/iso8859.txt')
    end

    it 'converts to UTF-8' do
      data = []
      blame.each do |commit, line|
        data << {
          commit: commit,
          line: line,
        }
      end

      expect(data.size).to eq(1)
      expect(data.first[:commit]).to be_kind_of(Bringit::Commit)
      expect(data.first[:line]).to eq('Ä ü')
    end
  end

  context 'unknown encoding' do
    let(:blame) do
      Bringit::Blame.new(repository, SeedRepo::EncodingCommit::ID, 'encoding/iso8859.txt')
    end

    it 'converts to UTF-8' do
      expect(CharlockHolmes::EncodingDetector).to receive(:detect).and_return(nil)
      data = []
      blame.each do |commit, line|
        data << {
          commit: commit,
          line: line,
        }
      end

      expect(data.size).to eq(1)
      expect(data.first[:commit]).to be_kind_of(Bringit::Commit)
      expect(data.first[:line]).to eq(' ')
    end
  end
end
