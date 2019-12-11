# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # A modifying FileOperation that compares a file's Exif Metadata with that
    # of a reference file and attempts to copy tags missing in the working file
    # from the reference file.
    #
    # Used to restore Exif tags that were not preserved during e.g. a file
    # conversion.
    #
    # *Caveat:* if this operation is applied to a file together with
    # ExifRedaction, it should be applied _before_ the latter, to avoid
    # redacted tags being restored.
    class ExifRestoration < FileOperation
      include ExifManipulable

      # :args: options
      #
      # Returns a new instance.
      #
      # ===== Options
      #
      # * <tt>skip_tags</tt> - _Exif_ tags to be ignored during restoration.
      #
      # The ExifManipulable mixin defines a set of _Exif_
      # {tags}[rdoc-ref:FilePipeline::FileOperations::ExifManipulable.file_tags]
      # that will always be ignored.
      def initialize(**opts)
        defaults = { skip_tags: [] }
        super(opts, defaults)
        @options[:skip_tags] += ExifManipulable.file_tags
      end

      # Returns the DROPPED_EXIF_DATA tag defined in CapturedDataTags.
      #
      # This operation will capture any _Exif_ tags and their values that could
      # not be written to the file created by the operation.
      def captured_data_tag
        CapturedDataTags::DROPPED_EXIF_DATA
      end

      # Writes a new version of <tt>src_file</tt> to <tt>out_file</tt> with all
      # writable _Exif_ tags from +original+ restored.
      #
      # Will return any _Exif_ tags that could not be written and their values
      # from the +original+ file as data.
      def operation(src_file, out_file, original)
        original_exif, src_file_exif = read_exif original, src_file
        values = missing_exif_fields(src_file_exif, original_exif)
        FileUtils.cp src_file, out_file
        write_exif out_file, values
      end
    end
  end
end
