# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a specified source
    # directory does not exist (or is not a directory).
    class SourceDirectoryError < StandardError
      # The directory that could not be found.
      attr_reader :directory

      def initialize(msg = nil, dir: nil)
        @directory = dir
        msg ||= "The source directory #{@directory} does not exist"
        super msg
      end
    end
  end
end
