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
  # next returned data in recovered_metadata
  module FileOperations
  end
end
