# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # This is an abstract class to be subclassed when file operations are
    # implemented.
    #
    # For the autoloading mechanism in FilePipeline.load to work, it is required
    # that subclasses are in defined in the module FilePipeline::FileOperations.
    #
    # The constructor (_#initialze_) must accept a doublesplat argument as the
    # only argument and should call +super+.
    #
    # Subclasses must implement an #operation method or override the #run
    # method.
    #
    # If the operation results in file type different than that of the file
    # that is passed to #run or #operation as <tt>src_file</tt>, the subclass
    # must have a #target_extension method that returns the appropriate
    # extension.
    class FileOperation
      # A Hash; any options used when performing #operation.
      attr_reader :options

      # Returns a new instance and sets #options.
      #
      # This can be called from subclasses.
      #
      # ===== Arguments
      #
      # * +defaults+ - Default options for the subclass (hash).
      # * +opts+ - Options passed to the sublass initializer (hash).
      def initialize(opts, defaults = {})
        @options = defaults.update(opts)
      end

      # Returns the NO_DATA tag.
      #
      # If the results returned by a subclass contain data, override this methos
      # to return the appropriate tag for the data. This tag can be used to
      # filter data captured by operations.
      #
      # Tags are defined in CapturedDataTags.
      def captured_data_tag
        CapturedDataTags::NO_DATA
      end

      # Returns the extension for +file+ (a string). This should be the
      # extension for the type the file created by #operation will have.
      #
      # If the #operation of a subclass will result in a different extension of
      # predictable type, define a #target_extension method.
      def extension(file)
        target_extension || File.extname(file)
      end

      # Returns a Results object with the Results#success set to +false+ and
      # any information returned by the operation in <tt>log_data</tt> (a string
      # error, array, or hash).
      def failure(log_data = nil)
        results false, log_data
      end

      # Returns the class name (string) of +self+ _without_ the names of the
      # modules that the class is nested in.
      def name
        self.class.name.split('::').last
      end

      # :args: src_file, out_file, original = nil
      #
      # To be implemented in subclasses. Should return any logged errors or data
      # produced (a string, error, array, or hash) or +nil+.
      #
      # ===== Arguments
      #
      # * <tt>src_file</tt> - Path for the file the operation will use as the
      #   basis for the new version it will create.
      # * <tt>out_file</tt> - Path the file created by the operation will be
      #   written to.
      # * +original+ - Path to the original, unmodified, file (optional).
      def operation(*_)
        raise 'not implemented'
      end

      # Returns a new Results object with the #descrip1tion of +self+,
      # +success+, and any information returned by the operation as
      # <tt>log_data</tt> (a string, error, array, or hash.)
      #
      # ===== Examples
      #
      #   error = StandardError.new
      #   warning = 'a warning occurred'
      #   log = [error, warning]
      #   data = { mime_type: 'image/jpeg' }
      #
      #   my_op = MyOperation.new
      #
      #   my_op.results(false, error)
      #   # => <Results @data=nil, @log=[error], ..., @success=false>
      #
      #   my_op.results(true, warning)
      #   # => <Results @data=nil, @log=[warning], ..., @success=true>
      #
      #   my_op.results(true, data)
      #   # => <Results @data=data, @log=[], ..., @success=true>
      #
      #   my_op.results(true, [warning, data])
      #   # => <Results @data=data, @log=[warning], ..., @success=true>
      #
      #   my_op.results(false, log)
      #   # => <Results @data=nil, @log=[error, warning], ..., @success=false>
      #
      #   my_op.results(false, [log, data])
      #   # => <Results @data=data, @log=[error, warning], ..., @success=false>
      #
      def results(success, log_data = nil)
        Results.new(self, success, log_data)
      end

      # Runs the operation on <tt>src_file</tt> and retunes an array with a
      # path for the file created by the operation and a Results object.
      #
      # Subclasses of FileOperation must either implement an #operation method,
      # or override the #run method, making sure it has the same signature and
      # kind of return value.
      #
      # The method will create a new path for the file produced by #operation to
      # be written to. This path will consist of +directory+ and a new basename.
      #
      # The optional +original+ argument can be used to reference another file,
      # e.g. when exif metadata tags missing in the <tt>src_file</tt> are to
      # be copied over from another file.
      def run(src_file, directory, original = nil)
        out_file = target directory, extension(src_file)
        log_data = operation src_file, out_file, original
        [out_file, success(log_data)]
      rescue StandardError => e
        FileUtils.rm out_file if File.exist? out_file
        [out_file, failure(e)]
      end

      # Returns a Results object with the Results#success set to +true+ and
      # any information returned by the operation in <tt>log_data</tt> (a string
      # error, array, or hash).
      def success(log_data = nil)
        results true, log_data
      end

      # Returns a new path to which the file created by the operation can be
      # written. The path will be in +directory+, with a new basename determined
      # by +kind+ and have the specified file +extension+.
      #
      # There are two options for the +kind+ of basename to be created:
      # * +:timestamp+ (_default_) - Creates a timestamp basename.
      # * +:random+ - Creates a UUID basename.
      #
      # The timestamp format is <tt>YYYY-MM-DDTHH:MM:SS.NNNNNNNNN</TT>.
      #
      # ===== Examples
      #
      #   file_operation.target('path/to/dir', '.png', :timestamp)
      #   # => 'path/to/dir/2019-07-24T09:30:12:638935761.png'
      #
      #   file_operation.target('path/to/dir', '.png', :random)
      #   # => 'path/to/dir/123e4567-e89b-12d3-a456-426655440000.png'
      def target(directory, extension, kind = :timestamp)
        filename = FilePipeline.new_basename(kind) + extension
        File.join directory, filename
      end

      # Returns +nil+.
      #
      # If the #operation of a subclass will result in a different extension of
      # predictable type, override this method to return the appropriate type.
      #
      # If, for instance, the operation will always create a <em>TIFF</em> file,
      # the implementation could be:
      #
      #   # Returns '.tiff'
      #   def target_extension
      #     '.tiff'
      #   end
      #
      def target_extension; end
    end
  end
end
