# frozen_string_literal: true

module FilePipeline
  # ...
  class Pipeline
    attr_reader :file_operations

    def initialize(*src_directories)
      src_directories.each { |dir| FilePipeline << dir }
      @file_operations = []
      yield(self) if block_given?
    end

    # Adds a file operation object implementing a #run method to
    # #file_operations.
    def <<(file_operation_instance)
      @file_operations << file_operation_instance
    end

    # Applies all #file_operations to a single versioned file.
    # Returns versioned_file.
    # TODO: call #finalize on versioned_file
    def apply_to(versioned_file)
      file_operations.each { |job| run job, versioned_file }
      versioned_file
    end

    # Applies all #file_operations to an Array of VersionedFile instances.
    # TODO: try using threads
    def batch_apply(versioned_files)
      versioned_files.map { |file| apply_to(file) }
    end

    # Initializes the class for <em>file_operation</em> (a String in
    # underscore notation) with _options_ and adds it to #file_operations.
    # Example: <tt> define_operation('ptiff_conversion', :tile => false)</tt>
    # will add a new instance of PtiffConversion with the tile option
    # turned off to #file_operations.
    # If the source file containing the file operation class definition is not
    # loaded, this methods will automatically try to locate it in the
    # FilePipeline default directory for file operations (
    # <tt>lib/file_pipeline/file_operations</tt> and any source directories
    # specified during initialization of _self_ and require it.
    def define_operation(file_operation, options = {})
      operation = FilePipeline.load file_operation
      self << operation.new(options)
      self
    end

    def empty?
      file_operations.empty?
    end

    # Applies _operation_ (a file operation object implementing the #run
    # method) to <em>versioned_file</em>.
    def run(operation, versioned_file)
      # TODO: call versioned_file#last_data (to be implemented with better name)
      versioned_file.modify do |version, path, original|
        operation.run version, path, original
      end
    end
  end
end
