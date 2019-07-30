# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # A FileOperation that will redact (delete) unwanted _Exif_ tags from a
    # file's metadata.
    #
    # This could be tags containing sensitive data, such as e.g. _GPS_ location
    # data.
    #
    # *Caveat:* if this operation is applied to a file together with
    # ExifRestoration, it should be applied _after_ the latter, to avoid
    # redacted tags being restored.
    class ExifRedaction < FileOperation
      include ExifManipulable

      # :args: options
      #
      # Returns a new instance.
      #
      # ===== Options
      #
      # * <tt>redact_tags</tt> - _Exif_ tags to be deleted.
      #
      def initialize(**opts)
        defaults = { redact_tags: [] }
        super(opts, defaults)
      end

      # Returns the DROPPED_EXIF_DATA tag defined in CapturedDataTags.
      #
      # This operation will capture all _Exif_ tags and their values are
      # declared in #options <tt>redact_tags</tt> that are redacted from the
      # file created by the operation.
      def captured_data_tag
        CapturedDataTags::DROPPED_EXIF_DATA
      end

      # :args: src_file, out_file
      #
      # Writes a new version of <tt>src_file</tt> to <tt>out_file</tt> with all
      # _Exif_ tags provided in the +redact_tags+ option deleted.
      #
      # Will return all deleted _Exif_ tags and their values as data.
      def operation(*args)
        src_file, out_file = args
        FileUtils.cp src_file, out_file
        delete_tags out_file, options[:redact_tags]
      end
    end
  end
end
