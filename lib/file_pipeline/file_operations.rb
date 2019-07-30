# frozen_string_literal: true

require 'ruby-vips'

require_relative 'file_operations/captured_data_tags'
require_relative 'file_operations/exif_manipulable'
require_relative 'file_operations/file_operation'
require_relative 'file_operations/log_data_parser'
require_relative 'file_operations/results'

module FilePipeline
  # Module that contains FileOperation and subclasses thereof that contain the
  # logic to perform file modifications, as well as associated classes, for
  # passing on information that was produced during a file operation.
  #
  # == Creating custom file operations
  #
  # === Module nesting
  #
  # File operation classes _must_ be defined in the FilePipeline::FileOperations
  # module for the autoloading mechanism in FilePipeline.load(file_operation)
  # to work.
  #
  #-- FIXME: drop this once module recognition and smarter paths are
  # implemented.
  #++
  #
  # === Implementing from scratch
  #
  # ==== Initializer
  #
  # The <tt>#initialize</tt> method _must_ take an +options+ argument (a hash
  # with a default value, or a <em>double splat</em>) and _must_ be exposed
  # through an <tt>#options</tt> getter method.
  #
  # The options passed can be any for the file operation to properly configure
  # a specific instance of a method.
  #
  # This requirement is imposed by the Pipeline.define_operation method, which
  # will automatically load and initialize an instance of the file operation
  # with any options provided as a hash.
  #
  # ===== Examples
  #
  #   class MyOperation
  #     attr_reader :options
  #
  #     # initializer with a default
  #     def initialize(options = {})
  #       @options = options
  #     end
  #   end
  #
  #   class MyOperation
  #     attr_reader :options
  #
  #     # initializer with a double splat
  #     def initialize(**options)
  #       @options = options
  #     end
  #   end
  #
  # Consider a file operation +CopyrightNotice+ that whill add copyright
  # information to an image file's _Exif_ metadata, the value for the copyright
  # tag could be passed as an option.
  #
  #  copyright_notice = CopyrightNotice.new(:copyright => 'The Photographer')
  #
  # ==== The <tt>#run</tt> method
  #
  # File operations _must_ implement a <tt>#run</tt> method that takes three
  # arguments (or a _splat_) in order to be used in a Pipeline.
  #
  # ===== Arguments
  #
  # The three arguments required for implementations of <tt>#run</tt> are:
  # * the path to the <em>file to be modified</em>
  # * the path to the _directory_ to which new files will be saved.
  # * the path to the <em>original file</em>, from which the first version in a
  #   succession of modified versions has been created.
  #
  # The <em>original file</em> will only be used by file operations that require
  # it for reference, e.g. to restore file metadata that was compromised by
  # other file operations.
  #
  # ===== Return value
  #
  # The method _must_ return the path to the file that was created by the
  # operation (perferrably in the _directory_). It _may_ also return a Results
  # object, containing the operation itself, a _success_ flag (+true+ or
  # +false+), and any logs or data returned by the operation.
  #
  # If results are returned with the path to the created file, both values must
  # be wrapped in an array, with the path as the first element, the results as
  # the second.
  #
  # ===== Example
  #
  #   def run(src_file, directory, original)
  #     # make a path to which the created file will be written
  #     out_file = File.join(directory, 'new_file_name.extension')
  #
  #     # create a Results object reporting success with no logs or data
  #     results = Results.new(self, true, nil)
  #
  #     # create a new out_file based on src_file in directory
  #     # ...
  #
  #     # return the path to the new file and the results object
  #     [out_file, results]
  #   end
  #
  # ==== Captured data tags
  #
  # Captured data tags can be used to filter captured data accumulated during
  # successive file operations (_see_ VersionedFile#captured_data_with(tag)).
  #
  # Operations that return data as part of the results _should_ respond to
  # <tt>:captured_data_tag</tt> and return one of the tags defined in
  # FileOperations::CapturedDataTags.
  #
  # ===== Example
  #
  #   # returns NO_DATA
  #   def captured_data_tag
  #     CapturedDataTags::NO_DATA
  #   end
  #
  # === Subclassing FileOperation
  #
  # The FileOperation class is an abstract superclass that provides a scaffold
  # to facilitate the creation of file operations that conform to the
  # requirements.
  #
  # It implements FileOperation#run, that takes the required three arguments and
  # returns the path to the newly created file and a Results object.
  #
  # When the operation was successful, Results#success will be +true+. When an
  # exception was raised, that exeption will be rescued and returned as the
  # Results#log, and Results#success will be +false+.
  #
  # The FileOperation#run method does not contain any logic to perform the
  # actual file operation, but will call an <tt>#operation</tt> method
  # (<em>see below</em>) that _must_ be defined in the subclass unless the
  # subclass overrides the <tt>#run</tt> method.
  #
  # The FileOperation#run method will generate the new path that is passed to
  # the <tt>#operation</tt> method, and to which the latter will write the new
  # version of the file. The new file path will need an appropriate file type
  # extension. The default behavior is to assume that the extension will be the
  # same as for the file that was passed in as the basis from which the new
  # version will be created. If the operation will result in a different file
  # type, the subclass _should_ define a <tt>#target_extension</tt> method that
  # returns the appropriate file extension.
  #
  # ==== Initializer
  #
  # The +initialize+ method _must_ take an +options+ argument (a hash with a
  # default value or a <em>double splat</em>).
  #
  # ===== Options and defaults
  #
  # The initializer can call +super+ and pass the +options+ hash and any
  # defaults (a hash with default options). This will update the defaults with
  # the actual options passed to +initialize+ and assign them to the
  # FileOperation#options attribute.
  #
  # If the initializer does not call +super+, it _must_ assign the options to
  # the <tt>@options</tt> instance variable or expose them through an
  # <tt>#options</tt> getter method.
  #
  # If it calls +super+ but must ensure some options are always set to a
  # specific value, those should be set after the call to +super+.
  #
  # ===== Examples
  #
  #   # initializer without defaults callings super
  #   def initialize(**options)
  #     super(options)
  #   end
  #
  #   # initializer with defaults calling super
  #   def initialize(**options)
  #     defaults = { :option_a => true, :option_b => false }
  #     super(options, defaults)
  #   end
  #
  #   # initializer with defaults calling super, ensures :option_c => true
  #   def initialize(**options)
  #     defaults = { :option_a => true, :option_b => false }
  #     super(options, defaults)
  #     @options[:option_c] = true
  #   end
  #
  #   # initilizer that does not call super
  #   def initialize(**options)
  #     @options = options
  #   end
  #
  # ==== The <tt>#operation</tt> method
  #
  # The <tt>#operation</tt> method contains the logic specific to a given
  # subclass of FileOperation and must be defined in that subclass unless the
  # <tt>#run</tt> method is overwritten.
  #
  # ===== Arguments
  #
  # The <tt>#operation</tt> method must accept three arguments:
  #
  # * the path to the <em>file to be modified</em>
  # * the path for the <em>file to be created</em> by the operation.
  # * the path to the <em>original file</em>, from which the first version in a
  #   succession of modified versions has been created.
  #
  # The <em>original file</em> will only be used by file operations that require
  # it for reference, e.g. to restore file metadata that was compromised by
  # other file operations.
  #
  # ===== Return Value
  #
  # The method _can_ return anything that can be interpreted by LogDataParser,
  # including nothing.
  #
  # It will usually return any log outpout that the logic of <tt>#operation</tt>
  # has generated, and/or data captured. If data is captured that is to be used
  # later, the subclass should override the FileOperation#captured_data_tag to
  # return the appropriate tag defined in CapturedDataTags.
  #
  # ===== Examples
  #
  #   # creates out_file based on src_file, captures metadata differences
  #   # between out_file and original, returns log messages and captured data
  #   def operation(src_file, out_file, original)
  #     captured_data = {}
  #     log_messages = []
  #
  #     # write the new version based on src_file to out_file
  #     # compare metadata of out_file with original, store any differences
  #     # in captures_data and append any log messages to log_messages
  #
  #     [log_messages, captured_data]
  #   end
  #
  #   # takes the third argument for the original file but does not use it
  #   # creates out_file based on src_file, returns log messages
  #   def operation(src_file, out_file, _)
  #     src_file, out_file = args
  #     log_messages = []
  #
  #     # write the new version based on src_file to out_file
  #
  #     log_messages
  #   end
  #
  #   # takes arguments as a splat and destructures them to avoid having the
  #   # unused thirs argumen
  #   # creates out_file based on src_file, returns nothing
  #   def operation(*args)
  #     src_file, out_file = args
  #
  #     # write the new version based on src_file to out_file
  #
  #     return
  #   end
  #
  # ==== Target file extensions
  #
  # If the file that the operation creates is of a different type than the file
  # the version is based upon, the class _must_ define the
  # <tt>#target_extension</tt> method that returns the appropriate file type
  # extension.
  #
  # In most cases, the resulting file type will be predictable (static), and in
  # such cases, the method can just return a string with the extension.
  #
  # An alternative would be to provide the expected extension as an #option
  # to the initializer.
  #
  # ===== Examples
  #
  #   # returns always '.tiff.
  #   def target_extension
  #     '.tiff'
  #   end
  #
  #   # returns the extension specified in #options +:extension+
  #   # my_operation = MyOperation(:extension => '.dng')
  #   def target_extension
  #     options[:extension]
  #   end
  #
  module FileOperations
  end
end
