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

  describe '#to_a' do
    subject { super().to_a }
    it { is_expected.to be_kind_of ::Array }
  end

  describe :decorate! do
    let(:file_count) { 3}

    it 'modifies the array in place' do
      count = 0
      subject.decorate! { |d| !d.nil? && count += 1 }
      expect(subject.to_a).to eq([1, 2, 3])
    end
  end

  context 'overflow handling' do
    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('3') }
        end
        it { expect(subject.size).to eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('3') }
          end
          it { expect(subject.size).to eq(3) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('0+') }
        end
        it { expect(subject.size).to eq(0) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('3') }
          end
          it { expect(subject.size).to eq(3) }
        end
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('10+') }
        end
        it { expect(subject.size).to eq(10) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('11') }
          end
          it { expect(subject.size).to eq(11) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 30 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('3+') }
        end
        it { expect(subject.size).to eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('11') }
          end
          it { expect(subject.size).to eq(11) }
        end
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('10') }
        end
        it { expect(subject.size).to eq(10) }
      end
    end
  end

  describe 'empty collection' do
    subject { Gitlab::Git::DiffCollection.new([]) }

    describe '#overflow?' do
      subject { super().overflow? }
      it { is_expected.to be_falsey }
    end

    describe '#empty?' do
      subject { super().empty? }
      it { is_expected.to be_truthy }
    end

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(0) }
    end

    describe '#real_size' do
      subject { super().real_size }
      it { is_expected.to eq('0')}
    end
  end

  def fake_diff(line_count)
    {'diff' => "DIFF\n" * line_count}
  end
end
