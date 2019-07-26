# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # This class contains the results from a FileOperation being run on a file.
    # Instances will be returned by the FileOperation#run method.
    #
    # Instances contain the file operation opbject that has produced +self+,
    # a flag for success, and any logs and data the operation may return.
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
      # * +operation+ - Must respond to +:name+ and +:options+.
      # * +success+ - +true+ or +false+.
      # * +log_data+ - A string, error, array, hash, or +nil+.
      #
      # ==== Examples
      #
      #   error = StandardError.new
      #   warning = 'a warning occurred'
      #   log = [error, warning]
      #   data = { mime_type: 'image/jpeg' }
      #
      #   my_op = MyOperation.new
      #
      #   Results.new(my_op, false, error)
      #   # => <Results @data=nil, @log=[error], ..., @success=false>
      #
      #   Results.new(my_op, true, warning)
      #   # => <Results @data=nil, @log=[warning], ..., @success=true>
      #
      #   Results.new(my_op, true, data)
      #   # => <Results @data=data, @log=[], ..., @success=true>
      #
      #   Results.new(my_op, true, [warning, data])
      #   # => <Results @data=data, @log=[warning], ..., @success=true>
      #
      #   Results.new(my_op, false, log)
      #   # => <Results @data=nil, @log=[error, warning], ..., @success=false>
      #
      #   Results.new(my_op, false, [log, data])
      #   # => <Results @data=data, @log=[error, warning], ..., @success=false>
      #
      #   Results.new(my_op, false, nil)
      #   # => <Results @data=nil, @log=nil, ..., @success=false>
      #
      def initialize(operation, success, log_data)
        @operation = operation
        @success = success
        @log, @data = LogDataParser.new log_data
      end

      def self.return_data(obj) # :nodoc:
        return [nil, obj] if obj.is_a? Hash
      end

      def self.return_log(obj) # :nodoc:
        flat_array = obj.is_a?(Array) &&
                     obj.none? { |i| i.is_a?(Array) || i.is_a?(Hash) }
        return unless flat_array

        [obj]
      end

      def self.return_log_and_data(obj) # :nodoc:
        log = obj.find { |i| !i.is_a? Hash }
        log = [log] unless log.is_a? Array
        data = obj.find { |i| i.is_a? Hash }
        [log, data]
      end

      def self.return_log_message(obj) # :nodoc:
        return if obj.is_a?(Array) || obj.is_a?(Hash)

        [[obj]]
      end

      def self.normalize_log_data(obj)
        return unless obj

        Results.return_data(obj) ||
          Results.return_log_message(obj) ||
          Results.return_log(obj) ||
          Results.return_log_and_data(obj)
      end

      # Returns +true+ if the operation was not succesful, +false+ otherwise.
      def failure
        !success
      end
    end
  end
end
