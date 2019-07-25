# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # Contains information about the results afters
    # +:operation+: an Operation Struct
    class Results
      # The object (usually an instance of a subclass of FileOperation) that
      # created +self+
      attr_reader :operation

      # +true+ if the operation has finished and produced a version file,
      # or +false+ if it encountered an error that caused it to terminate.
      attr_reader :success

      # Array with log messages from operations.
      attr_reader :log

      # Hash with any data returned from an operation.
      attr_reader :data

      # Returns a new instance.
      #
      # ==== Arguments
      #
      # * +operation+ - Must respond to #name and #options
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
