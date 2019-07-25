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
        @log, @data = Results.normalize_log_data log_data
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

      # :args: log_data_object
      #
      # Accepts an object that may be an individual error or message, a _log_
      # (arrays of errors and messages), _data_ (hash), or an array containing
      # combintions of the above and returns a normalized array with the _log_
      # at index 0 and _data_ at index 1: <tt>[log, data]</tt>.
      #
      # ==== Examples
      #
      # When passed +nil+, will return +nil+:
      #
      #   Results.normalize_log_data(nil)
      #   # => nil
      #
      # When passed individual messages or errors, those will be wrapped in an
      # array, which will be the log:
      #
      #   Results.normalize_log_data(StandardError.new)
      #   # => [[#<StandardError: StandardError>]]
      #
      #   Results.normalize_log_data('a warning')
      #   # => [['a warning']]
      #
      # This is also true when the message or error is passed along with data:
      #
      #   Results.normalize_log_data(['a warning', { a_key: 'some value' }])
      #   # => [['a warning'], { a_key: 'some value' }]
      #
      #
      # When passed a hash with data, returns an array with +nil+ and the hash:
      #
      #   Results.normalize_log_data(['a warning', { a_key: 'some value' }])
      #   # => [nil, { a_key: 'some value' }]
      #
      # When passed an arry that does contain neither arrays nor hashes, this
      # is considered to be the _log_.
      #
      #   Results.normalize_log_data(['a warning', StandardError.new])
      #   # => [['a warning', #<StandardError: StandardError>]]
      #
      # When passed an array containing an array and a hash, the inner array is
      # interpreted as the log, the hash as the data.
      #
      #   log = ['a warning', 'another warning']
      #   data = { a_key: 'some value' }
      #
      #   Results.normalize_log_data([log, data])
      #   # => [['a warning', 'another warning'], { a_key: 'some value' }]
      #
      #   Results.normalize_log_data([data, log])
      #   # => [['a warning', 'another warning'], { a_key: 'some value' }]
      #
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
