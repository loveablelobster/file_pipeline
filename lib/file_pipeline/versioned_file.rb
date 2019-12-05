# frozen_string_literal: true

module FilePipeline
  # VersionedFile creates a directory where it stores any versions of _file_.
  class VersionedFile
    include FileOperations::ExifManipulable

    # The basename of the versioned file.
    attr_reader :basename

    # A hash with file paths as keys, information on the modifications applied
    # to create the version as values (instances of FileOperations::Results).
    attr_reader :history

    # The path to the original file of _self_.
    attr_reader :original

    # A String that is appended to the file basename when the file written
    # by #finalize is not replacing the original.
    attr_reader :target_suffix

    extend Forwardable

    # Returns a two-dimesnional array, where each nested array has two items;
    # the file operation object and data captured by the operartion (if any).
    #
    # <tt>[[description_object, data_or_nil], ...]</tt>
    delegate captured_data: :history

    # Returns any data captured by <tt>operation_name</tt>.
    #
    # If multiple instances of one operation class have modified the file,
    # pass any +options+ the specific instance of the operation was initialized
    # with as the optional second argument.
    delegate captured_data_for: :history

    # Returns an array with all data captured by operations with +tag+.
    #
    # Tags are defined in FileOperations::CapturedDataTags
    delegate captured_data_with: :history

    # Returns an array of triplets (arryas with three items each): the name of
    # the file operation class (a string), options (a hash), and the actual log
    # (an array).
    delegate log: :history

    # Returns an array with paths to the version files of +self+ (excluding
    # #original).
    delegate versions: :history

    # Returns a new instance with +file+ as the #original.
    #
    # ===== Arguments
    #
    # * +file+ - Path to the file the instance will be based on. That file
    #   should not be touched unless #finalize is called with the +:overwrite+
    #   option set to +true+.
    #
    # *Caveat* it can not be ruled out that buggy or malignant file operations
    # modify the original.
    #
    # ===== Options
    #
    # <tt>target_suffix</ttm> is a string to be appended to the file that
    # will be written by #finalize (the last version) if #finalize is to
    # preserve the original. It is recommended to use a randomized string
    # (_default_) to avoid clashes with other files in the directory.
    def initialize(file, target_suffix: SecureRandom.hex(4))
      raise Errors::MissingVersionFileError, file: file unless File.exist? file

      @original = file
      @basename = File.basename(file, '.*')
      @history = Versions::History.new
      @directory = nil
      @target_suffix = target_suffix
      history[original] = nil
    end

    # Adds a new version to #history and returns _self_.
    #
    # <tt>version_info</tt> must be a path to an existing file or an array with
    # the path and optionally a FileOperations::Results instance:
    # <tt>['path/to/file', results_object]</tt>.
    # Will move the file to #directory if it is in another directory.
    def <<(version_info)
      file, info = version_info
      if info&.failure
        raise Errors::FailedModificationError, info: info, file: original
      end

      version = validate(file)
      @history[version] = info
      self
    rescue StandardError => e
      reset
      raise e
    end

    # Returns +true+ if there are #versions (file has been modified).
    #
    # *Warning:* It will also return +true+ if the file has been cloned.
    def changed?
      current != original
    end

    # Creates a new identical version of #current. Will only add the path of
    # the file to history, but no FileOperations::Results.
    def clone
      filename = FilePipeline.new_basename + current_extension
      clone_file = Versions.copy(current, directory, filename)
      self << clone_file
    end

    # Returns the path to the current file or the #original if no versions
    # have been created.
    def current
      versions.last || original
    end

    # Returns the file extension for the #current file.
    def current_extension
      File.extname current
    end

    # Returns the path to the directory where the versioned of +self+ are
    # stored. Creates the directory if it does not exist.
    def directory
      @directory ||= workdir
    end

    # Writes the #current version to #basename, optionally the #target_suffix,
    # and the #current_extension in #original_dir. Deletes all versions and
    # resets the #history to an empty Hash. Returns the path to the written
    # file.
    #
    # If the optional block is passed, it will be evaluated before the file is
    # finalized.
    #
    # ===== Options
    #
    # * +overwrite+ - +true+ or +false+
    #   * +false+ (_default_) - The #target_suffix will be appended to the
    #     #basename and the #original will be preserved.
    #   * +true+ - The finalized version will replace the #original.
    def finalize(overwrite: false)
      yield(self) if block_given?
      filename = overwrite ? replacing_trarget : preserving_taget
      FileUtils.rm original if overwrite
      @original = Versions.copy(current, original_dir, filename)
    ensure
      reset
    end

    # Returns the Exif metadata
    #
    # ===== Options
    #
    # * <tt>:for_version</tt> - +current+ or +original+
    #   * +current+ (_default_) - Metadata for the #current file will be
    #     returned.
    #   * +original+ - Metadata for the #original file will be returned.
    #
    #--
    # TODO: when file is not an image file, this should return other metadata
    # than exif.
    #++
    def metadata(for_version: :current)
      if %i[current original].include? for_version
        file = public_send(for_version)
      end
      file ||= for_version
      read_exif(file).first
    end

    # Creates a new version.
    # Requires a block that must return a path to an existing file or an array
    # with the path and optionally a FileOperations::Results instance:
    # <tt>['path/to/file', results_object]</tt>.
    #
    # The actual file modification logic will be in the block.
    #
    # The block must take three arguments: for the #current file (from which the
    # modified version will be created), the work #directory (to where the
    # modified file will be written), and the #original file (which will only
    # be used in modifications that need the original file for reference, such
    # as modifications that restore file metadata that was lost in other
    # modifications).
    def modify
      self << yield(current, directory, original)
    end

    # Returns the directory where #original is stored.
    def original_dir
      File.dirname original
    end

    # Returns a hash into which all captured data from file operations with the
    # FileOperations::CapturedDataTags::DROPPED_EXIF_DATA has been merged.
    def recovered_metadata
      return unless changed?
      captured_data_with(FileOperations::CapturedDataTags::DROPPED_EXIF_DATA)
        &.reduce({}) { |recovered, data| recovered.merge data }
    end

    alias touch clone

    private

    # Returns the filename for a target file that will not overwrite the
    # original.
    def preserving_taget
      basename + '_' + target_suffix + current_extension
    end

    # Returns the filename for a target file that will overwrite the
    # original.
    def replacing_trarget
      basename + current_extension
    end

    # Deletes the work directory and resets #versions
    def reset
      FileUtils.rm_r directory, force: true
      history.clear!
    end

    # Validates if file exists and has been stored in #directory.
    def validate(file)
      return current unless file

      raise Errors::MissingVersionFileError, file: file unless File.exist? file

      return file if File.dirname(file) == directory

      Versions.move file, directory, File.basename(file)
    end

    # Creates the directory containing all version files. Directory name is
    # composed of the basename plus '_version'.
    #
    # Raises SystemCallError if the directory already exists.
    def workdir
      subdir = basename + '_versions'
      filedir = File.dirname(original)
      dirname = File.join filedir, subdir
      FileUtils.mkdir(dirname)
      File.path dirname
    end
  end
end
