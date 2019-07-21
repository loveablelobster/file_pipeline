# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a a FileOperation in a
    # Pipeline returns failure.
    # Error class for exceptions that are raised when a specified source
    # directory does not exist (or is not a directory).
    class SourceDirectoryError < StandardError
      def initialize(msg = nil, dir: nil)
        @directory = dir
        msg ||= "The source directory #{@directory} does not exist"
        super msg
      end
    end
  end
end
