# frozen_string_literal: true

module FilePipeline
  # VersionedFile creates a directory where it stores any versions of _file_.
  class VersionedFile
    # Copies the _src_ file to <em>/directory/filename<em>.
    def self.copy(src, dir, filename)
      dest = FilePipeline.path(dir, filename)
      FileUtils.cp src, dest
      dest
    end

    # Moves the _src_ file to <em>/directory/filename<em>.
    def self.move(src, dir, filename)
      dest = FilePipeline.path(dir, filename)
      FileUtils.mv src, dest
      dest
    end

    # The basename of the versioned file
    attr_reader :basename

    # A Hash with file paths (String) as keys, VersionInfo as values.
    attr_reader :history

    # The path to the original file of _self_.
    attr_reader :original

    # A String that is appended to the file basename when the file written
    # by #finalize is not replacing the original.
    attr_reader :target_suffix

    # Returns a new instance for _file_.
    # <em>target_suffix</em> is a String to be appended to the file that
    # will be written by #finalize (the last version) if #finalize is to
    # preserve the original. It is recommended to use a UUID to avoid clashes
    # with other files in the directory.
    def initialize(file, target_suffix: SecureRandom.uuid)
      @original = file
      @basename = File.basename(file, '.*')
      @history = {}
      @directory = nil
      @target_suffix = target_suffix
    end

    # Adds _file_ to #versions if validation passes, moves the file to
    # #directory if it is in another directory.
    # Returns _self_.
    def <<(result_array)
      file, info = result_array
      raise Errors::FailedModificationError, info: info if info&.failure

      version = validate(file)
      @history[version] = info
      self
    rescue StandardError => e
      reset
      raise e
    end

    # Creates a new identical version of current. Will only add the path of
    # the file to history, but no information (value will be nil).
    def clone
      filename = FilePipeline.new_basename + current_extension
      clone_file = VersionedFile.copy(current, directory, filename)
      self << clone_file
    end

    # Returns a String with the path to the current file.
    # Returns the path to the original if no versions have been created
    # through #clone or #modify.
    def current
      versions.last || original
    end

    # Returns the fle extension for the #current file.
    def current_extension
      File.extname current
    end

    # Returns a String with the path to the directory where the versioned
    # file is stored.
    # Creates the directory if it does not exist.
    def directory
      @directory ||= workdir
    end

    # Returns a tow-dimesnional Array, where each nested Array has two items,
    # the operation descrtiption Struct and data captured by the operartion.
    def captured_data
      filter_history :data
    end

    # Returns the data captured by <em>operation_name</em> and any _options_
    # the operation was initialized with.
    def captured_data_for(operation_name, **options)
      raw_data = captured_data.filter do |operation, _|
        operation.name == operation_name &&
          options.all? { |k, v| operation.options[k] == v }
      end
      raw_data.map(&:last)
    end

    # Returns the final version as basename + final extension, calls #destroy
    # use a finalizer? #define_finalizer
    def finalize(overwrite: false)
      filename = overwrite ? replacing_trarget : preserving_taget
      FileUtils.rm original if overwrite
      @original = VersionedFile.copy(current, original_dir, filename)
    ensure
      reset
    end

    # Returns an Array of triplets (arryas with three items) of
    # operation class name (a String), options (a Hash), and the actual log
    # (an Array).
    def log
      filter_history(:log)
        .map { |operation, info| [operation.name, operation.options, info] }
    end

    # Creates a new version.
    # <em>target_extension</em>: the file extension of the target file format.
    # Requires a block that must return a String with a path to an existing
    # file. The block should take to arguments: one for the current file, and
    # one for the directory where to store the file.
    def modify
      self << yield(current, directory, original)
    end

    def original_dir
      File.dirname original
    end

    # Returns an Array with filepaths to version files of _self_.
    def versions
      history.keys
    end

    private

    # item = :data or :log
    def filter_history(item)
      history.inject([]) do |results, (_, info)|
        next results unless info.respond_to?(item) && info.public_send(item)

        results << [info.operation, info.public_send(item)]
      end
    end

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
      @history = {}
    end

    # Validates if file exists and has been stored in #directory.
    def validate(file)
      raise Errors::MissingVersionFileError, file: file unless File.exist? file

      return file if File.dirname(file) == directory

      VersionedFile.move file, directory, File.basename(file)
    end

    # Creates the directory containing all version files. Directory name is
    # composed of the basename plus '_version'.
    def workdir
      subdir = basename + '_versions'
      filedir = File.dirname(original)
      dirname = Pathname.new(filedir) / subdir
      FileUtils.mkdir(dirname)
      File.path dirname
    end
  end
end
