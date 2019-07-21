# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a new version is added,
    # but no actual file is associated with it.
    class MissingVersionFileError < StandardError
      def initialize(msg = nil, file: nil)
        @file = file
        msg ||= "File missing for version '#{@file}'"
        super msg
      end
    end
  end
end
