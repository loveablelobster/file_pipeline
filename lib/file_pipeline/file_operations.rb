# frozen_string_literal: true

require_relative 'file_operations/exif_manipulable'
require_relative 'file_operations/file_operation'
require_relative 'file_operations/log_data_parser'
require_relative 'file_operations/results'

module FilePipeline
  # Module that contains FileOperation and subclasses thereof that contain the
  # logic to perform file modifications, as well as associated classes, for
  # passing on information that was produced during a file operation.
  #
  # == Creating custom file operations
  #
  # === Subclassing FileOperation
  #
  # ==== Defining the #operation method
  #
  #   def operation(*args)
  #     src_file, out_file = args
  #
  #     # do something
  #
  #   end
  #
  # ==== Returning logs and data
  #
  # When data is to be captured, define the define the method
  # #captured_data_tag to return the appropriate tag.
  #
  module FileOperations
    # Module that contains constants used as tags for the kinds of data captured
    # by file operations.
    module CapturedDataTags
      # Tag for operations that do not return data
      NO_DATA = :no_data

      # Tag for operations that return _Exif_ metadata that has not been
      # preserved (by accident or intention) in a file.
      DROPPED_EXIF_DATA = :dropped_exif_data
    end
  end
end
