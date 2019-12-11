# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # A non-modifying FileOperation that compares a file's _Exif_ Metadata with
    # that of a reference file and returns tags missing in the working file as
    # captured data.
    #
    # Used to recover _Exif_ tags that were not preserved during e.g. a file
    # conversion.
    class ExifRecovery < FileOperation
      include ExifManipulable

      # :args: options
      #
      # Returns a new instance.
      #
      # ===== Options
      #
      # * <tt>skip_tags</tt> - _Exif_ tags to be ignored during comparison.
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
      # Instances of ExifRecovery will capture any _Exif_ tags and their values
      # that are present in the reference file but missing in the working file.
      def captured_data_tag
        CapturedDataTags::DROPPED_EXIF_DATA
      end

      # Instances of ExifRecovery do not modify the working file.
      def modifies?
        false
      end

      # Compares the _Exif_ metadata of <tt>src_file</tt> with that of
      # +original+ and returns all tags that are present in +original+ but
      # missing in <tt>src_file</tt>.
      def operation(src_file, _, original)
        original_exif, src_file_exif = read_exif original, src_file
        missing_exif_fields(src_file_exif, original_exif)
      end
    end
  end
end
