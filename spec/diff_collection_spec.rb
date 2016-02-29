require 'spec_helper'

describe Gitlab::Git::DiffCollection do
  subject do
    Gitlab::Git::DiffCollection.new(
      iterator,
      max_files: max_files,
      max_lines: max_lines,
      all_diffs: all_diffs,
    )
  end
  let(:iterator) { Array.new(file_count, fake_diff(line_count)) }
  let(:file_count) { 0 }
  let(:line_count) { 1 }
  let(:max_files) { 10 }
  let(:max_lines) { 100 }
  let(:all_diffs) { false }

  its(:to_a) { should be_kind_of ::Array }

  describe :map! do
    let(:file_count) { 3}

    it 'modifies the array in place' do
      count = 0
      subject.map! { |d| !d.nil? && count += 1 }
      subject.to_a.should eq([1, 2, 3])
    end
  end

  context 'overflow handling' do
    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('3') }
        it { subject.size.should eq(3) }
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_true }
        its(:real_size) { should eq('0+') }
        it { subject.size.should eq(0) }
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:too_many_files?) { should be_true }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('10+') }
        it { subject.size.should eq(10) }
      end

      context 'and too many lines' do
        let(:line_count) { 30 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_true }
        its(:real_size) { should eq('3+') }
        it { subject.size.should eq(3) }
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:too_many_files?) { should be_false }
        its(:too_many_lines?) { should be_false }
        its(:real_size) { should eq('10') }
        it { subject.size.should eq(10) }
      end
    end
  end

  def fake_diff(line_count)
    {'diff' => "DIFF\n" * line_count}
  end
end
