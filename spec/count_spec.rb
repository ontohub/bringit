require 'spec_helper'

describe Gitlab::Git::Count do
  describe :lines do
    [
      ["", 0],
      ["foo", 1],
      ["foo\n", 1],
      ["foo\n\n", 2],
    ].each do |string, line_count|
      it "counts #{line_count} lines in #{string.inspect}" do
        Gitlab::Git::Count.lines(string).should eq(line_count)
      end
    end
  end
end
