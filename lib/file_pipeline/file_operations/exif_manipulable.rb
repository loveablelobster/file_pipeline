# frozen_string_literal: true

require 'multi_exiftool'

module FilePipeline
  module FileOperations
    # Mixin with methods to facilitate work with _Exif_ metadata.
    module ExifManipulable
      # Returns an Array of tags to be ignored during comparison. These can
      # be merged with an ExifManipulable including FileOperation's options
      # to skip tags (e.g. the <tt>skip_tags</tt> option in ExifRestoration).
      def self.file_tags
        %w[FileSize FileModifyDate FileAccessDate FileInodeChangeDate
           FilePermissions FileType FileTypeExtension MIMEType]
      end

      def self.parse_tag_error(message) # :nodoc:
        /Warning: Sorry, (?<tag>\w+) is not writable/
          .match(message) { |match| match[:tag] }
      end

      def self.strip_path(str) # :nodoc:
        str.sub(%r{ - \/?(\/|[-:.]+|\w+)+\.\w+$}, '')
      end

      # Redacts (deletes) all <tt>tags_to_delete</tt> in <tt>out_file</tt>.
      def delete_tags(out_file, tags_to_delete)
        exif, = read_exif out_file
        values = exif.select { |tag| tags_to_delete.include? tag }
        values_to_delete = values.transform_values { nil }
        log, = write_exif out_file, values_to_delete
        [log, { metadata: values }]
      end

      # Compares to hashes with exif tags and values and returns a hash with
      # the tags that are present in <tt>other_exif</tt> but absent in
      # <tt>this_exif</tt>.
      def missing_exif_fields(this_exif, other_exif)
        other_exif.delete_if do |tag, _|
          this_exif.key?(tag) || options[:skip_tags].include?(tag)
        end
      end

      # :args: error_messages, exif
      #
      # Takes an array of <tt>error_messages</tt> and a hash (+exif+) with tags
      # and their values and parses errors where tags could not be written.
      #
      # Returns an array with a log (any messages that were not errors where a
      # tag could not be written) and data (a hash with any tags that could not
      # be written, and the associated values from +exif+)
      def parse_exif_errors(errs, values)
        errs.each_with_object(LogDataParser.template) do |message, info|
          errors, data = info
          tag = ExifManipulable.parse_tag_error(message)
          if tag
            (data[:metadata] ||= {}).store tag, values[tag]
            next info
          end
          errors << ExifManipulable.strip_path(message)
          info
        end
      end

      # Reads exif information for one or more +files+. Returns an array of
      # hashes, one for each file, with tags and their values.
      def read_exif(*files)
        file_paths = files.map { |f| File.expand_path(f) }
        results, errors = MultiExiftool.read file_paths
        raise 'Error reading Exif' unless errors.empty?

        results.map(&:to_h)
      end

      # Writes +values+ (a hash with exif tags as keys) to +out_file+.
      #
      # Returns an array with a log (an array of messages - strings) and a
      # hash with all tags/values that could not be written.
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
