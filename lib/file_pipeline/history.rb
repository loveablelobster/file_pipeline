# frozen_string_literal: true

module FilePipeline
  class History
    def initialize()
      @entries = {}
    end

    def [](key)
      @entries[key]
    end

    def []=(key, value)
      entry = @entries.fetch key, []
      entry << value
      @entries[key] = entry
      value
    end

    # Returns a two-dimesnional array, where each nested array has two items;
    # the file operation object and data captured by the operartion (if any).
    #
    # <tt>[[description_object, data_or_nil], ...]</tt>
    def captured_data
      filter :data
    end

    # Returns any data captured by <tt>operation_name</tt>.
    #
    # If multiple instances of one operation class have modified the file,
    # pass any +options+ the specific instance of the operation was initialized
    # with as the optional second argument.
    def captured_data_for(operation_name, **options)
      captured_data.filter { |op, _| matches? op, operation_name, options }
        .map(&:last)
    end

    # Returns an array with all data captured by operations with +tag+.
    #
    # Tags are defined in FileOperations::CapturedDataTags
    def captured_data_with(tag)
      # TODO: returning nil if empty needs spec
      return if @entries.empty?

      captured_data.filter { |op, _| op.captured_data_tag == tag }
        .map(&:last)
    end

    # TODO: needs spec
    def clear!
      @entries.clear
    end

    # TODO: needs spec
    def empty?
      @entries.empty?
    end

    # Returns an array of triplets (arryas with three items each): the name of
    # the file operation class (a string), options (a hash), and the actual log
    # (an array).
    def log
      filter(:log).map { |op, results| [op.name, op.options, results] }
    end

    # Returns an array with paths to the version files of +self+ (excluding
    # #original).
    def versions
      @entries.keys
    end

    private

    def filter(item)
      @entries.values
              .flatten
              .select(&item)
              .map { |results| [results.operation, results.public_send(item)] }
    end

    def matches?(operation, name, opts)
      operation.name == name && opts.all? { |k, v| operation.options[k] == v }
    end
  end
end
