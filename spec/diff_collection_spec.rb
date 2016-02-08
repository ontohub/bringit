require 'spec_helper'

describe Gitlab::Git::DiffCollection do
  subject do
    Gitlab::Git::DiffCollection.new(
      max_files: max_files,
      max_lines: max_lines,
      all_diffs: all_diffs,
    )
  end
  let(:max_files) { 10 }
  let(:max_lines) { 100 }
  let(:all_diffs) { false }

  its(:to_a) { should be_kind_of ::Array }

  describe :map! do
    it 'modifies the array in place' do
      3.times { subject.add fake_diff(1) }
      count = 0
      subject.map! { |d| !d.nil? && count += 1 }
      subject.to_a.should eq([1, 2, 3])
    end
  end

  context 'overflow handling' do
    let(:file_count) { 0 }
    before do
      file_count.times do
        subject.add(fake_diff(line_count))
        break if subject.full?
      end
    end

    it 'raises an exception when adding too much' do
      expect { 20.times { subject.add(fake_diff(1)) } }.to raise_error
    end

    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('3') }
        it { subject.to_a.size.should eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:too_many_files?) { should be_false }
          its(:too_many_lines?) { should be_false }
          its(:real_size) { should eq('3') }
          it { subject.to_a.size.should eq(3) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_true }
        its(:real_size) { should eq('3') }
        it { subject.to_a.size.should eq(0) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:too_many_files?) { should be_false }
          its(:too_many_lines?) { should be_false }
          its(:real_size) { should eq('3') }
          it { subject.to_a.size.should eq(3) }
        end
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:too_many_files?) { should be_true }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('10+') }
        it { subject.to_a.size.should eq(10) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:too_many_files?) { should be_false }
          its(:too_many_lines?) { should be_false }
          its(:real_size) { should eq('11') }
          it { subject.to_a.size.should eq(11) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 30 }

        its(:too_many_files?) { should be_true }
        its(:too_many_lines?) { should be_true }
        its(:real_size) { should eq('10+') }
        it { subject.to_a.size.should eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:too_many_files?) { should be_false }
          its(:too_many_lines?) { should be_false }
          its(:real_size) { should eq('11') }
          it { subject.to_a.size.should eq(11) }
        end
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('10') }
        it { subject.to_a.size.should eq(10) }
      end
    end
  end

  FakeDiff = Struct.new(:size)

  def fake_diff(line_count)
    FakeDiff.new(line_count)
  end
end