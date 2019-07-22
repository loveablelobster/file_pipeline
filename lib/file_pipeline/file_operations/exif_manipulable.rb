# frozen_string_literal: true

require 'multi_exiftool'

module FilePipeline
  module FileOperations
    # Mixin with methods to work with Exif metadata.
    module ExifManipulable
      # Returns an Array of tags to be ignored during comparison. These can
      # be merged with an ExifManipulable including FileOperation's options
      # to skip tags (e.g. ExifRestoration#options +skip_tags+).
      def self.file_tags
        %w[FileSize FileModifyDate FileAccessDate FileInodeChangeDate
           FilePermissions FileType FileTypeExtension MIMEType]
      end

      def self.parse_tag_error(message)
        /Warning: Sorry, (?<tag>\w+) is not writable/
          .match(message) { |match| match[:tag] }
      end

      def self.strip_path(str)
        str.sub(%r{ - \/?(\/|[-:.]+|\w+)+\.\w+$}, '')
      end

      def missing_exif_fields(this_exif, other_exif)
        other_exif.to_h.delete_if do |tag, _|
          this_exif.to_h.key?(tag) || options[:skip_tags].include?(tag)
        end
      end

      def parse_exif_errors(errs, values)
        errs.each_with_object([[], {}]) do |message, info|
          errors, data = info
          tag = ExifManipulable.parse_tag_error(message)
          if tag
            data[tag] = values[tag]
            next info
          end
          errors << ExifManipulable.strip_path(message)
          info
        end
      end

      def read_exif(*files)
        file_paths = files.map { |f| File.expand_path(f) }
        results, errors = MultiExiftool.read file_paths
        raise 'Error reading Exif' unless errors.empty?

        results
      end

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
