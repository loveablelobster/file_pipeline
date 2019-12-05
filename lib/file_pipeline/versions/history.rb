# frozen_string_literal: true

module FilePipeline
  module Versions
    # History objects keep track of a VersionedFile instances versions names and
    # any associated logs or data for each version.
    class History
      # Returns a new instance.
      def initialize
        @entries = {}
      end

      # Retrieves the _results_ object for the <tt>version_name</tt>.
      def [](version_name)
        @entries[version_name]
      end

      # Associates the +results+ with the <tt>version_name</tt>.
      def []=(version_name, results)
        entry = @entries.fetch version_name, []
        entry << results
        @entries[version_name] = entry.compact
      end

      # Returns a two-dimensional array, where each nested array has two items:
      # * the file operation object
      # * data captured by the operartion (if any).
      #
      # <tt>[[file_operation_object, data_or_nil], ...]</tt>
      def captured_data
        filter :data
      end

      # Returns any data captured by <tt>operation_name</tt>.
      #
      # If multiple instances of one operation class have modified the file,
      # pass any +options+ the specific instance of the operation was
      # initialized with as the optional second argument.
      def captured_data_for(operation_name, **options)
        return if empty?

        captured_data.filter { |op, _| matches? op, operation_name, options }
                     .map(&:last)
      end

      # Returns an array with all data captured by operations with +tag+.
      # Returns an empty array if there is no data for +tag+.
      #
      # Tags are defined in FileOperations::CapturedDataTags
      def captured_data_with(tag)
        captured_data.filter { |op, _| op.captured_data_tag == tag }
                     .map(&:last)
      end

      # Clears all history entries (version names and associated results).
      def clear!
        @entries.clear
      end

      # Returns +true+ if +self+ has no entries (version names and associated
      # results), +true+ otherwise.
      def empty?
        @entries.empty?
      end

      # Returns an array of triplets (arryas with three items each):
      #  * Name of the file operation class (String).
      #  * Options for the file operation instance (Hash).
      #  * The log (Array).
      def log
        filter(:log).map { |op, results| [op.name, op.options, results] }
      end

      # Returns a two-dimensional Array where every nested Array will consist
      # of the version name (file path) at index +0+ and +nil+ or an Array with
      # all _results_ objects for the version at index +1+:
      #
      # <tt>[version_name, [results1, ...]]</tt>
      def to_a
        @entries.to_a
      end

      # Returns an array with paths to the version files of +self+ (excluding
      # #original).
      def versions
        @entries.keys
      end

      private

      # Filters entries in self by +item+ (<tt>:log</tt> or <tt>:data</tt>).
      def filter(item)
        @entries.values.flatten.select(&item).map do |results|
          [results.operation, results.public_send(item)]
        end
      end

      # Returns +true+ if +name+ matches the _name_ attribute of +operation+ and
      # +options+ matches the options the operation instance is initialized
      # with.
      def matches?(operation, name, opts)
        operation.name == name && opts.all? { |k, v| operation.options[k] == v }
      end
    end
  end
end
