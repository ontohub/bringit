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
          break if _too_many_files?

          diff = Gitlab::Git::Diff.new(raw)
          @line_count += diff.line_count
          break if _too_many_lines?

          yield @array[i] = diff
        end
      end

      def too_many_files?
        return @too_many_files unless @too_many_files.nil?
        
        populate!
        @too_many_files = _too_many_files?
      end

      def too_many_lines?
        return @too_many_lines unless @too_many_lines.nil?
        
        populate!
        @too_many_lines = _too_many_lines?
      end

      def size
        @size ||= count # forces a loop through @iterator
      end

      def real_size
        @real_size ||= @iterator.count
      end

      def map!
        each_with_index do |elt, i|
          @array[i] = yield(elt)
        end
      end

      private

      def populate!
        return if @populated
        
        each { nil } # force a loop through all diffs
        @populated = true
        nil
      end

      def _too_many_files?
        !@all_diffs && (@file_count > @max_files)
      end

      def _too_many_lines?
        !@all_diffs && (@line_count > @max_lines)
      end
    end
  end
end
