# frozen_string_literal: true

module FilePipeline
  module Versions
    # Validator objects verify the version file and results returned by a
    # FileOperation.
    #
    # They will validate:
    # - that the version file existst
    # - that it is in the correct directory
    # - that the file operation has not returned any failures
    class Validator
      extend Forwardable

      # File for the version that resulted from a FileOperation.
      attr_reader :file

      # FileOperation::Results object.
      attr_reader :info

      # Returns a new instance.
      #
      # ===== Arguments
      #
      # * <tt>version_info</tt> - path to an existing file or an array with the
      #   path and optionally a FileOperations::Results instance.
      # * +directory+ - directory where the file is expected (the working
      #   directory of a VersionedFile).
      # * +filename+ - name of the file to be returned if the file operation was
      #   was non-modifying (usually the VersionedFile#original).
      def initialize(version_info, directory, filename)
        @file, @info = [version_info].flatten
        @directory = directory
        @filename = filename
      end

      # Validates file, directory, and info for <tt>version_info</tt> in the
      # context of <tt>versioned_file</tt>.
      #
      # ===== Arguments
      #
      # * <tt>version_info</tt> - path to an existing file or an array with the
      #   path and optionally a FileOperations::Results instance.
      # * <tt>versioned_file</tt> - an object that responds to #original and
      # returns a file path, and #directory and returns a directory path.
      def self.[](version_info, versioned_file)
        new(version_info, versioned_file.directory, versioned_file.original)
          .validate_info
          .validate_file
          .validate_directory
          .then { |validator| [validator.file, validator.info] }
      end

      # Returns +true+ when there is no file for the version (result of a
      # non-modifying file operation), +false+ otherwise.
      def unmodified?
        @file.nil?
      end

      # Raises MisplacedVersionFileError if #file is not in #directory.
      def validate_directory
        return self if unmodified? || File.dirname(@file) == @directory

        raise Errors::MisplacedVersionFileError.new file: @file,
                                                    directory: @directory
      end

      # Raises MissingVersionFileError if #file does not exist on the file
      # system.
      def validate_file
        return self if unmodified? || File.exist?(@file)

        raise Errors::MissingVersionFileError.new file: @file
      end

      # Raises FailedModificationError if the file operation generatint the
      # #info failed.
      def validate_info
        return self unless @info&.failure

        raise Errors::FailedModificationError.new info: @info, file: @filename
      end
    end
  end
end
