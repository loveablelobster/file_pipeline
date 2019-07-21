# frozen_string_literal: true

module FilePipeline
  module FileOperations
    # FileOperation classes MUST
    # be defined in PigeonHole::FilePipeline
    # be subclass of Pigeonhole::FilePipeline::FileOperation
    # - implement the #file_extension method
    # - implement the #run method that takes two args: src_file and out_file
    # - accept a doublesplat argument as the only argument in the constructor
    class FileOperation
      # Contains a description of _self_:
      # +:name+: the Class name of the operation (String)
      # +:options+: the options for the operation when #run was called
      Description = Struct.new(:name, :options)

      attr_reader :options

      def initialize(defaults, opts)
        @options = defaults.merge(opts)
      end

      # Returns a Description Struct with the class name of _self_ and
      # #options.
      def description
        class_name = self.class.name.split('::').last
        Description.new class_name, options
      end

      # if extension is expected to always be the same for a subclass,
      # overwrite it in the subclass returning a static value
      # example: `extension(file)`
      def extension(file)
        File.extname(file)
      end

      # Returns a Results Struct with the _success_ attribute set to +false+,
      # _log_ (an Array), and _data_ (a Hash).
      def failure(log_data = nil)
        results false, log_data
      end

      # To be implemented in subclasses. Should return an Array with another
      # array (the log) and a hash (data returned from the operation)
      # data
      def operation
        raise 'not implemented'
      end

      # Returns a Results Struct with _description_, _success_ (+true+ or
      # +false+), _log_ (an Array), and _data_ (a Hash) attributes.
      # _description_ will be set to #description.
      def results(success, log_data = nil)
        Results.new(description, success, log_data)
      end

      def run(src_file, directory_path, original = nil)
        out_file = target directory_path, extension(src_file)
        log_data = operation src_file, out_file
        [out_file, success(log_data)]
      rescue => error
        log ||= error.message
        [out_file, failure(log_data)]
      end

      # Returns a Results Struct with the _success_ attribute set to +true+,
      # _log_ (an Array), and _data_ (a Hash).
      def success(log_data = nil)
        results true, log_data
      end

      def target(directory, extension, kind = :timestamp)
        filename = FilePipeline.new_basename(kind) + extension
        File.path Pathname.new(directory).join(filename)
      end
    end
  end
end
