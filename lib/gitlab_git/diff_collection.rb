module Gitlab
  module Git
    class DiffCollection
      include Enumerable

      def self.empty
        new([], all_diffs: true)
      end

      def initialize(iterator, options)
        @iterator = iterator
        @max_files = options.delete(:max_files)
        @max_lines = options.delete(:max_lines)
        @all_diffs = options.delete(:all_diffs)
        if !@all_diffs && !(@max_files && @max_lines)
          raise 'You must pass both :max_files and :max_lines or set :all_diffs to true.'
        end

        @file_count, @line_count = 0, 0
        @array = Array.new
      end

      def each
        @iterator.each_with_index do |raw, i|
          if !@array[i].nil?
            yield @array[i]
            next
          end
          
          @file_count += 1
          break if too_many_files?

          diff = Gitlab::Git::Diff.new(raw)
          @line_count += diff.line_count
          break if too_many_lines?

          yield @array[i] = diff
        end
      end

      def too_many_files?
        !@all_diffs && (@file_count > @max_files)
      end

      def too_many_lines?
        !@all_diffs && (@line_count > @max_lines)
      end

      def real_size
        return @file_count.to_s if @all_diffs

        result = [@max_files, @file_count].min.to_s
        result << '+' if too_many_files? || too_many_lines?
        result
      end

      def map!
        each_with_index do |elt, i|
          @array[i] = yield(elt)
        end
      end
    end
  end
end
