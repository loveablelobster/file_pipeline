# frozen_string_literal: true

require 'securerandom'

require_relative 'file_pipeline/errors'
require_relative 'file_pipeline/file_operations'
require_relative 'file_pipeline/versions'
require_relative 'file_pipeline/versioned_file'
require_relative 'file_pipeline/pipeline'

# Module that contains classes to build a file processing pipeline that applies
# a defined batch of file operations non-destructively to a VersionedFile.
module FilePipeline
  # Constant for the defualt directory for file operations.
  DEFAULT_DIR = 'file_pipeline/file_operations/default_operations'

  # Adds _directory_ to the Array of #source_directories which will be
  # searched for source files when loading file operations.
  # _directory_ will be prepended. Therefore, directories will be searcherd
  # in reverse order of them being added.
  def self.<<(directory)
    directory_path = File.expand_path directory
    return source_directories if source_directories.include? directory_path

    no_dir = !File.directory?(directory_path)
    raise Errors::SourceDirectoryError.new dir: directory if no_dir

    @src_directories.prepend directory_path
  end

  # Returns the constant for the <em>file_operation</em> class. If the
  # constant is not defined, will try to require the source file.
  def self.load(file_operation)
    const = file_operation.split('_').map(&:capitalize).join
    FilePipeline.load_file(file_operation) unless const_defined? const
    const_get "FileOperations::#{const}"
  rescue NameError
    # TODO: implement autogenerating module names from file_operation src path
    const_get const
  end

  # Will search for <em>src_file</em> in .source_directories and require the
  # file if.
  def self.load_file(src_file)
    src_file += '.rb' unless src_file.end_with? '.rb'
    src_path = FilePipeline.source_path src_file
    if src_path.nil?
      raise Errors::SourceFileError.new(
        file: src_file,
        directories: FilePipeline.source_directories
      )
    end
    require src_path
  end

  # Creates a file basename consisting of either a timestamp or a UUID,
  # depending on the _kind_ argument (+:timestamp+ or +:random+; default:
  # +:timestamp+)
  def self.new_basename(kind = :timestamp)
    case kind
    when :random
      SecureRandom.uuid
    when :timestamp
      Time.now.strftime('%Y-%m-%dT%H:%M:%S.%N')
    end
  end

  # Returns a String with the <em>/directory/filename</em>.
  def self.path(dir, filename)
    File.join dir, filename
  end

  # Returns an array of directory paths that may contain source files for
  # file operation classes.
  def self.source_directories
    return @src_directories if @src_directories

    @src_directories = [FilePipeline.path(__dir__, DEFAULT_DIR)]
  end

  # Searches .source_directories and for _file_, and returns the full path
  # (directory and filename) for the first match or nil if the file is
  # nowhere found. Since directories are added in reverse order (see .<<)
  # this will give redefinitions of file operations in custom directories
  # precedence over the default directory, thus allowing overriding of file
  # operation definitions.
  def self.source_path(file)
    FilePipeline.source_directories.each do |dir|
      full_path = FilePipeline.path(dir, file)
      return full_path if File.exist? full_path
    end
    nil
  end
end
