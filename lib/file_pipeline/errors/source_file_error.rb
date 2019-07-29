# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a specified source
    # directory does not exist (or is not a directory).
    class SourceFileError < StandardError
      # The source file that could not be located.
      attr_reader :file

      # The directories for source files that were registered with FilePipeline
      # and searched at the time the error was raises.
      attr_reader :directories

      def initialize(msg = nil, file: nil, directories: nil)
        @file = file
        @directories = directories
        default_msg = "The source file #{@file} was not found. Searched in:\n"
        msg ||= @directories.inject(default_msg) do |str, dir|
          str + "\t- #{dir}\n"
        end
        super msg
      end
    end
  end
end
