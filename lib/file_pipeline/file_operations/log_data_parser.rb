# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # This class parses an object that may be a hash, array other object or
    # +nil+.
    #
    # If it is initialized with an array, that array may contain another array,
    # a hash, any objects, or +nil+
    #
    # The resulting instance will behave like an array and always have two
    # elements:
    # * +nil+ or an array containing all arguments that are not a hash at index
    #   0
    # * +nil+ or a hash at index 1.
    #
    # ==== Examples
    #
    # When passed +nil+:
    #
    #   LogDataParser.new(nil).to_a
    #   # => [nil, nil]
    #
    # When initialized with individual strings or errors, those will be wrapped
    # in an array:
    #
    #   LogDataParser.new(StandardError.new).to_a
    #   # => [[#<StandardError: StandardError>], nil]
    #
    #   LogDataParser.new('a warning').to_a
    #   # => [['a warning'], nil]
    #
    # This is also true when initialized with individual messages or errors
    # along with data:
    #
    #   LogDataParser.new(['a warning', { a_key: 'some value' }]).to_a
    #   # => [['a warning'], { a_key: 'some value' }]
    #
    #   LogDataParser.new(['a warning', { a_key: 'some value' }, 'an error']).to_a
    #   # => [['a warning', 'an error'], { a_key: 'some value' }]
    #
    # When initialized with a hash, the array will be +nil+ and the hash:
    #
    #   LogDataParser.new(['a warning', { a_key: 'some value' }]).to_a
    #   # => [nil, { a_key: 'some value' }]
    #
    # When initialized with an arry that does contain neither arrays nor hashes,
    # it will become the first element of the resulting array, with second being
    # +nil+.
    #
    #   LogDataParser.new(['a warning', StandardError.new]).to_a
    #   # => [['a warning', #<StandardError: StandardError>], nil]
    #
    # When initialized with an array containing an array and a hash, the inner
    # array is will be the first element, the hash the second
    #
    #   log = ['a warning', 'another warning']
    #   data = { a_key: 'some value' }
    #
    #   LogDataParser.new([log, data]).to_a
    #   # => [['a warning', 'another warning'], { a_key: 'some value' }]
    #
    #   LogDataParser.new([data, log])
    #   # => [['a warning', 'another warning'], { a_key: 'some value' }]
    #
    class LogDataParser
      # :args: object
      #
      # Returns a new instance for +object+, which may be +nil+, a hash, another
      # object, or an array, that may itself contain a hash, an array, or other
      # objects.
      def initialize(obj)
        @log_data = nil
        parse obj
      end

      private

      def method_missing(method_name, *args, &block)
        super unless respond_to_missing? method_name.to_sym

        @log_data.public_send method_name, *args, &block
      end

      def parse(obj)
        @log_data = case obj
                    when Array
                      parse_array obj
                    when Hash
                      [nil, obj]
                    when nil
                      [nil, nil]
                    else
                      [[obj], nil]
                    end
      end

      def parse_array(obj)
        return [obj, nil] if obj.none? { |e| e.respond_to? :each }

        parse_nested obj
      end

      def parse_nested(obj)
        obj.each_with_object([]) do |element, ld|
          case element
          when Array
            ld[0] = element
          when Hash
            ld[1] = element
          else
            (ld[0] ||= []) << element
          end
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @log_data.respond_to?(method_name.to_sym) || super
      end
    end
  end
end
