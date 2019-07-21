# frozen_string_literal: true

require 'multi_exiftool'

module FilePipeline
  module FileOperations
    class ExifRestoration < FileOperation
      FILE_TAGS = %w[FileSize FileModifyDate FileAccessDate FileInodeChangeDate
                     FilePermissions FileType FileTypeExtension MIMEType].freeze

      WRITE_ERROR_RXP = /Warning: Sorry, (?<tag>\w+) is not writable/.freeze
      STRIP_PATH_RXP = / - \/?(\/|[-:.]+|\w+)+\.\w+$/.freeze

      # Returns a new instance.
      # _opts_:
      # +skip_tags+: exif tags to be ignored during restoration.
      def initialize(**opts)
        defaults = {
          skip_tags: [],
        }
        super(defaults, opts)
        @options[:skip_tags] = @options[:skip_tags].concat FILE_TAGS
      end

      # TODO: write Exif mixin, move this method there.
      def missing_exif_fields(this_exif, other_exif)
        other_exif.to_h.delete_if do |tag, _|
          this_exif.to_h.key?(tag) || options[:skip_tags].include?(tag)
        end
      end

      def operation(src_file, out_file, values)
        FileUtils.cp src_file, out_file
        write_exif out_file, values
      end

      # TODO: write Exif mixin, move this method there.
      def parse_exif_errors(errs, values)
        errs.each_with_object([[], {}]) do |message, info|
          next if WRITE_ERROR_RXP.match(message) do |match|
            tag = match[:tag]
            info.last[tag] = values[tag]
          end
          info.first << message.sub(STRIP_PATH_RXP, '')
        end
      end

      # TODO: write Exif mixin, move this method there.
      def read_exif(*files)
        file_paths = files.map { |f| File.expand_path(f) }
        results, errors = MultiExiftool.read file_paths
        raise 'Error reading Exif' unless errors.empty?

        results
      end

      def run(src_file, directory_path, original)
        original_exif, src_file_exif = read_exif original, src_file
        values = missing_exif_fields(src_file_exif, original_exif)
        out_file = target directory_path, extension(src_file)
        log_data = operation src_file, out_file, values
        [out_file, success(log_data)]
      rescue => error
        puts error.message
        puts error.backtrace
        FileUtils.rm out_file
        [out_file, failure(log_data)]
      end

      # TODO: write Exif mixin, move this method there.
      def write_exif(out_file, values)
        writer = MultiExiftool::Writer.new
        writer.filenames = Dir[File.expand_path(out_file)]
        writer.overwrite_original = true
        writer.values = values
        return if writer.write

        parse_exif_errors(writer.errors, values)
      end
    end
  end
end
