# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a a FileOperation in a
    # Pipeline returns failure.
    class FailedModificationError < StandardError
      # The file opration that caused the error.
      attr_reader :info

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * +msg+ - error message for the exception. If none provided, the 
      #   instance will be initialized with the #default_message.
      #
      # ===== Options
      #
      # * <tt>info</tt> - a FileOperations::Results object or an object.
      # * <tt>file</tt> - path to the file thas was being processed.
      def initialize(msg = nil, info: nil, file: nil)
        @file = file
        @info = info
        msg ||= default_message
        super msg
      end

      # Returns the backtrace of the error that caused the exception.
      def original_backtrace
        original_error&.backtrace&.join("\n")
      end

      # Returns the error that caused the exception.
      def original_error
        @info.log.find { |item| item.is_a? Exception }
      end

      private

      # Appends the backtrace of the error that caused the exception to the 
      # #default_message.
      def append_backtrace(str)
        return str + "\n" unless original_backtrace

        str + " Backtrace:\n#{original_backtrace}"
      end

      # Appends the message of the error that caused the exception to the 
      # #default_message.
      def append_error(str)
        return str unless original_error

        str += "\nException raised by the operation:"\
          " #{original_error.inspect}."
        append_backtrace str
      end

      # Returns a String with the #message for +self+.
      def default_message
        if info&.respond_to?(:operation) && info&.respond_to?(:log)
          msg = "#{info.operation&.name} with options"\
            " #{info.operation&.options} failed on #{@file}."
          append_error msg
        else
          'Operation failed'
        end
      end
    end
  end
end
