# frozen_string_literal: true

module FilePipeline
  # Instances of Pipeline hold a defined set of operations that perform
  # modifications of files.
  #
  # The operations are applied to a VersionedFile in the order they are added
  # to the instance. To implement custom operations, it is easiest to write a
  # subclass of FileOperations::FileOperation.
  #
  # The class can be initialized with an optional block to add file
  # operations:
  #
  #   Pipeline.new do |pipeline|
  #     pipeline.define_operation('scale',
  #                               width: 1280, height: 1024)
  #     pipeline.define_operation('ptiff_conversion',
  #                               tile_width: 64, tile_height: 64)
  #   end
  #
  class Pipeline
    # An array of file operations that will be applied to files in the order
    # they have been added.
    attr_reader :file_operations

    # Returns a new instance.
    #
    # If <tt>src_directories</tt> are provided, they will be added to
    # FilePipeline.source_directories.
    #
    # ===== Arguments
    #
    # * <tt>src_directories</tt> - one or more paths to directories where
    #   classes for file operations are defined.
    def initialize(*src_directories)
      src_directories.each { |dir| FilePipeline << dir }
      @file_operations = []
      yield(self) if block_given?
    end

    # Adds a file operation object #file_operations. The object must implement
    # a _run_ method (see FileOperations::FileOperation#run for details).
    def <<(file_operation_instance)
      unless file_operation_instance.respond_to? :run
        raise TypeError, 'File operations must implement a #run method'
      end

      @file_operations << file_operation_instance
    end

    # Applies all #file_operations to a <tt>versioned_file</tt> and returns it.
    def apply_to(versioned_file)
      file_operations.each { |job| run job, versioned_file }
      versioned_file
    end

    # Applies all #file_operations to <tt>versioned_files</tt> (an array) and
    # returns it.
    def batch_apply(versioned_files)
      versioned_files.map { |file| Thread.new(file) { apply_to(file) } }
                     .map(&:value)
    end

    # Initializes the class for <tt>file_operation</tt> (a string in
    # underscore notation) with +options+, adds it to #file_operations, and
    # returns +self+.
    #
    # If the source file containing the file operation's class definition is not
    # loaded, this method will try to locate it in the
    # FilePipeline.source_directories and require it.
    #
    # ===== Examples
    #
    # Define single operation:
    #
    #   pipeline.define_operation('ptiff_conversion', :tile => false)
    #
    # Chaining:
    #
    #   pipeline.define_operation('scale', width: 1280, height: 1024)
    #           .define_operation('ptiff_conversion')
    #
    def define_operation(file_operation, options = {})
      operation = FilePipeline.load file_operation
      self << operation.new(options)
      self
    end

    # Returns +true+ if no #file_operations are defined.
    def empty?
      file_operations.empty?
    end

    # Applies +operation+ to <tt>versioned_file</tt>.
    #
    # +operation+ must be an object implementing a _run_ method that takes three
    # arguments (see FileOperations::FileOperation#run ).
    def run(operation, versioned_file)
      versioned_file.modify do |version, directory, original|
        operation.run version, directory, original
      end
    end
  end
end
