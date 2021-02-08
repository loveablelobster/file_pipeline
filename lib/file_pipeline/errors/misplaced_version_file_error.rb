# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a new version is added,
    # but the file is not in the VersionedFile's working directory.
    class MisplacedVersionFileError < StandardError
      # Path for of the misplaced file for the version.
      attr_reader :file

      # Path for the directory where the file should have been (the
      # VersionedFile's working directory).
      attr_reader :directory

      def initialize(msg = nil, file: nil, directory: nil)
        @file = file
        @directory = directory
        msg ||= default_message
        super msg
      end

      private

      def default_message
        "File #{File.basename @file} was expected in #{@directory},"\
        " but was in #{File.dirname @file}."
      end
    end
  end
end
