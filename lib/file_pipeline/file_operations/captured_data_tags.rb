# frozen_string_literal: true

module FilePipeline
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
