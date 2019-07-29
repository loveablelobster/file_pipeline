# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # A FileOperation that compares Exif Metadata in two files and copies tags
    # missing in one from the other. Used to restore Exif tags that were not
    # preserved during e.g. a file conversion.
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
      # ==== Options
      #
      # * <tt>skip_tags</tt> - _Exif_ tags to be ignored during restoration.
      #
      # The ExifManipulable mixin defines a set of _Exif_ tags that will always
      # be ignored. These are tags relating to the file properties (e.g.
      # filesize, MIME-type) that will have been altered by any prior operation,
      # such as file format conversions.
      def initialize(**opts)
        defaults = { skip_tags: [] }
        super(defaults, opts)
        @options[:skip_tags] += ExifManipulable.file_tags
      end

      # :args: src_file, out_file
      #
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
