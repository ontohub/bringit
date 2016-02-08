module Gitlab
  module Git
    module Count
      LINE_SEP = "\n"

      def self.lines(string)
        case string[-1]
        when nil
          0
        when LINE_SEP
          string.count(LINE_SEP)
        else
          string.count(LINE_SEP) + 1
        end
      end
    end
  end
end
