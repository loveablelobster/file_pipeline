# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # Contains information about the results after _self_ was #run.
    # +:operation+: an Operation Struct
    # +:success+: +true+ or +false+
    # +:log+: an Array with log messages from operations, e.g. errors
    # +:data+: a Hash with any data returned from operations.
    class Results
      attr_reader :operation
      attr_reader :success
      attr_reader :log
      attr_reader :data

      # Returns a new instance.
      def initialize(operation, success, log_data)
        @operation = operation
        @success = success
        @log, @data = Results.parse_log_data log_data
      end

      # Finds _log_ (an Array) and _data_ (a Hash) objects in _obj_ and returns
      # an Array with the _log_ at index 0 and the _data_ at index 1.
      def self.parse_log_data(obj)
        return unless obj
        return [nil, obj] if obj.is_a?(Hash)
        return [[obj]] unless obj.is_a?(Array)
        return [obj] if obj.is_a?(Array) && obj.none? { |i| i.is_a?(Array) }

        log = obj.find { |i| !i.is_a?(Hash) }
        data = obj.find { |i| i.is_a?(Hash) }
        [log, data]
      end

      # Returns +true+ if the operation was not succesful, +false+ otherwise.
      def failure
        !success
      end
    end
  end
end
