# frozen_string_literal: true

require 'ruby-vips'

require_relative 'file_operations/captured_data_tags'
require_relative 'file_operations/exif_manipulable'
require_relative 'file_operations/file_operation'
require_relative 'file_operations/log_data_parser'
require_relative 'file_operations/results'

module FilePipeline
  # Module that contains FileOperation and subclasses thereof that contain the
  # logic to perform file modifications, as well as associated classes, for
  # passing on information that was produced during a file operation.
  module FileOperations
  end
end
