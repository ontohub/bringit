module Gitlab
  module Git
    class DiffCollection
      class TooManyDiffs < ::StandardError ; end

      def self.empty
        new(all_diffs: true)
      end

      def initialize(options)
        @max_files = options.delete(:max_files)
        @max_lines = options.delete(:max_lines)
        @all_diffs = options.delete(:all_diffs)
        if !@all_diffs && !(@max_files && @max_lines)
          raise 'You must pass both :max_files and :max_lines or set :all_files to true.'
        end

        @file_count, @line_count = 0, 0
        @array = Array.new
      end

      def add(diff)
        raise TooManyDiffs, "Can only hold #@max_files files and #@max_lines lines." if full?
        @file_count += 1
        @line_count += diff.size
        if !too_many_files? && !too_many_lines?
          @array << diff
        end
      end

      def full?
        too_many_files?
      end

      def too_many_files?
        !@all_diffs && (@file_count > @max_files)
      end

      def too_many_lines?
        !@all_diffs && (@line_count > @max_lines)
      end

      def real_size
        too_many_files? ? "#{@max_files}+" : @file_count.to_s
      end

      def to_a
        @array
      end

      def map!
        @array.each_with_index do |elt, i|
          @array[i] = yield(elt)
        end
      end
    end
  end
end