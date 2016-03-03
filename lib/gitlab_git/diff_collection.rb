module Gitlab
  module Git
    class DiffCollection
      include Enumerable

      DEFAULT_LIMITS = { max_files: 100, max_lines: 5000 }.freeze

      def initialize(iterator, options={})
        @iterator = iterator
        @max_files = options.fetch(:max_files, DEFAULT_LIMITS[:max_files])
        @max_lines = options.fetch(:max_lines, DEFAULT_LIMITS[:max_lines])
        @all_diffs = !!options.fetch(:all_diffs, false)

        @line_count = 0
        @overflow = false
        @array = Array.new
      end

      def each
        @iterator.each_with_index do |raw, i|
          # First yield cached Diff instances from @array
          if @array[i]
            yield @array[i]
            next
          end

          # We have exhausted @array, time to create new Diff instances or stop.
          break if @overflow

          if !@all_diffs && i >= @max_files
            @overflow = true
            break
          end

          # Going by the number of files alone it is OK to create a new Diff instance.
          diff = Gitlab::Git::Diff.new(raw)

          @line_count += diff.line_count
          if !@all_diffs && @line_count >= @max_lines
            # This last Diff instance pushes us over the lines limit. We stop and
            # discard it.
            @overflow = true
            break
          end

          yield @array[i] = diff
        end
      end

      def empty?
        !@iterator.any?
      end

      def overflow?
        populate!
        !!@overflow
      end

      def size
        @size ||= count # forces a loop through @iterator
      end

      def real_size
        populate!

        if @overflow
          "#{size}+"
        else
          size.to_s
        end
      end

      def decorate!
        each_with_index do |element, i|
          @array[i] = yield(element)
        end
      end

      private

      def populate!
        return if @populated

        each { nil } # force a loop through all diffs
        @populated = true
        nil
      end
    end
  end
end
