# frozen_string_literal: true
require 'pry-byebug'
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

    def captured_data
      filter :data
    end

    def captured_data_for(operation_name, **options)
      captured_data.filter { |op, _| matches? op, operation_name, options }
        .map(&:last)
    end
   
    def captured_data_with(tag)
      captured_data.filter { |op, _| op.captured_data_tag == tag }
        .map(&:last)
    end

    def log
      filter(:log).map { |op, results| [op.name, op.options, results] }
    end

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
