# frozen_string_literal: true

require_relative '../exif_manipulable'

module FilePipeline
  module FileOperations
    # A FileOperation that compares Exif Metadata in two files and copies tags
    # missing in one from the other. Used to restore Exif tags that were not
    # preserved during e.g. a file conversion.
    class ExifRestoration < FileOperation
      include ExifManipulable

      # Returns a new instance.
      # _opts_:
      # +skip_tags+: exif tags to be ignored during restoration.
      def initialize(**opts)
        defaults = { skip_tags: [] }
        super(defaults, opts)
        @options[:skip_tags] += ExifManipulable.file_tags
      end

      def operation(src_file, out_file, values)
        FileUtils.cp src_file, out_file
        write_exif out_file, values
      end

      def run(src_file, directory_path, original)
        original_exif, src_file_exif = read_exif original, src_file
        values = missing_exif_fields(src_file_exif, original_exif)
        out_file = target directory_path, extension(src_file)
        log_data = operation src_file, out_file, values
        [out_file, success(log_data)]
      rescue => e
        puts e.message
        puts e.backtrace
        log_data.first << e
        FileUtils.rm out_file if File.exist? out_file
        [out_file, failure(log_data)]
      end
    end
  end
end
