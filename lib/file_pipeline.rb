# frozen_string_literal: true

require 'securerandom'

require_relative 'file_pipeline/errors'
require_relative 'file_pipeline/file_operations'
require_relative 'file_pipeline/versioned_file'
require_relative 'file_pipeline/pipeline'

# Module that contains classes to build a file processing pipeline that applies
# a defined batch of file operations non-destructively to a VersionedFile.
#
# == Usage
#
# The basic usage is to create a new Pipeline object and define any file
# operations that are to be performed, apply it to a VersionedFile object
# initialized with the image to be processed, and finalize the versioned file.
#
#   require 'file_pipeline'
#
#   # create a new instance of Pipeline
#   my_pipeline = FilePipeline::Pipeline.new
#
#   # configure an operation to scale an image to 1280 x 960 pixels
#   my_pipeline.define_operation('scale', :width => 1280, :height => 960)
#
#   # create an instance of VersionedFile for the file '~/image.jpg'
#   image = FilePipeline::VersionedFile.new('~/image.jpg')
#
#   # apply the pipeline to the versioned file
#   my_pipeline.apply_to(image)
#
#   # finalize the versioned file, replacing the original
#   image.finalize(:overwrite => true)
#
# === Setting up a Pipeline
#
# Pipeline objects can be set up to contain default file operations included in
# the gem or with custom file operations (see FileOperations for instructions on
# how to create custom operations).
#
# ==== Basic set up with default operations
#
# To define an operation, pass the class name of the operation in underscore
# notation and without the containing module name, and any options to
# Pipeline#define_operation.
#
# The example below adds an instance of FileOperations::PtiffConversion with
# the <tt>:tile_width</tt> and <tt>:tile_height</tt> options each set to 64
# pixels.
#
#   my_pipeline = Pipeline.new
#   my_pipeline.define_operation('ptiff_conversion',
#                                :tile_width => 64, :tile_height => 64)
#
# Chaining is possible
#
#   my_pipeline = Pipeline.new
#   my_pipeline.define_operation('scale', width: 1280, height: 1024)
#              .define_operation('exif_restoration')
#
# Alternatively, the operations can be defined during initialization by passing
# a block to Pipeline.new.
#
#   my_pipeline = Pipeline.new do |pipeline|
#     pipeline.define_operation('scale', width: 1280, height: 1024)
#     pipeline.define_operation('exif_restoration')
#   end
#
# When using the default operations included in the gem, it is sufficient to
# call Pipeline#define_operation with the desired operations and options.
#
# ==== Using custom FileOperations
#
# When file operations are to be used that are not included in the gem, place
# the source files for the class definitions in one or more directories and
# initialize the Pipeline object with the directory paths.
#
# Directories are added to FilePipeline.source_directories in reverse order, so
# that directories added later will have precedence over earlier ones when
# source files are searched. The default operations included in the gem will
# looked up last. This allows for overriding of operations without changing the
# code in exsisting classes.
#
# If, for example, there are two directories with custom file operation classes,
# <tt>'~/custom_operations'</tt> and <tt>'~/other_operations'</tt>, the new
# instance of Pipeline can be set up to look for source files first in
# <tt>'~/other_operations'</tt>, then in <tt>'~/custom_operations'</tt>, and
# finally in the included default operations.
#
# The basename for source files _must_ be the class name in underscore notation
# without the containing module name.
#
# If, for instance, the operation is <tt>FileOperations::MyOperation</tt>,
# the source file should be <tt>'my_operation.rb'</tt>
#
#   my_pipeline = Pipeline.new('~/custom_operations', '~/other_operations')
#   my_pipeline.define_operation('my_operation')
#
# Instructions for how to write file operations are provided in the
# documentation for the FileOperations module.
#
# === Nondestructive application to files
#
# Pipeline instances work on instances of VersionedFile, which allows for
# non-destructive application of all file operations.
#
# VersionedFile instances are created by calling VersionedFile.new with the
# path of the file to work with.
#
#   # create an instance of VersionedFile for the file '~/image.jpg'
#   image = VersionedFile.new('~/image.jpg')
#
# As long as no operations have been applied, this will have no effect in the
# file system. Only when the first operation is applied will VersionedFile
# create a working directory in the same directory as the original file. The
# working directory will have the basename of the file basename without
# extension and the suffix <tt>'_versions'</tt>.
#
# For further details, refer to the VersionedFile documentaion.
#
# Instances of Pipeline can be applied to a singe VersionedFile instance with
# the Pipeline#apply_to method, or to an array of versioned files with the
# Pipeline#batch_apply method.
#
# For further details, refer to the Pipeline documentation.
#
# === Accessing file metadata and captured data.
#
# *Caveat*: this currently only works for _Exif_ metadata of image files.
#
# VersionedFile provides access to a files metadata via VersionedFile#metadata.
# Both the metadata for the original file and the current (latest) version can
# be accessed.
#
#   image = VersionedFile.new('~/image.jpg')
#
#   # access the metadata for the current version
#   image.metadata
#
# Note that if no file operations have been applied by a pipeline object, this
# will return the metadata for the original, which in that case is the current
# (latest) version.
#
# To explicitly get the metadata for the original file even if there are newer
# versions available, pass the <tt>:for_version</tt> option with the symbol
# <tt>:original</tt>:
#
#   # access the metadata for the original file
#   image.metadata(for_version: :original)
#
# Some file operations can comprise metadata (delete elements). Many image
# processing libraries will not preserve all _Exif_ tags and their values, but
# only write a small subset of tags to the file they create. In these cases,
# the FileOperations::ExifRestoration operation can try to restore the tags that
# have been discarded, but it can not write all tags. It will store all data
# that it could not write back to the file and return it as captured data.
#
# Likewise, if the FileOperations::ExifRedaction is applied to delete sensitive
# tags (e.g. GPS location data), it will return all deleted exif tag-value-pairs
# as captured data.
#
# VersionedFile#recovered_metadata is a shorthand to retrieve a hash with all
# metadata that was deleted or could not be restored by operations.
#
#   delete_tags = ['CreatorTool', 'Software']
#
#   my_pipeline = Pipeline.new do |pipeline|
#     pipeline.define_operation('scale', width: 1280, height: 1024)
#     pipeline.define_operation('exif_restoration')
#     Pipeline.define_operation('exif_redaction', :redact_tags => delete_tags)
#   end
#
#   image = VersionedFile.new('~/image.jpg')
#   my_pipeline.apply_to(image)
#
#   image.recovered_metadata
#
# For information on retrieving other kinds of captured data, refer to
# VersionedFile#captured_data, VersionedFile#captured_data_for, and
# VersionedFile#captured_data_with.
#
# === Finalizing files
#
# Once all file operations of a pipeline object have been applied to a
# versioned file object, it can be finalized by calling VersionedFile#finalize.
#
# Finalization will write the current version to the same directory that
# contains the original. It will by default preserve the original by adding
# a suffix to the basename of the final version. If the <tt>:overwrite</tt>
# option for the method is passed with +true+, it will delete the original and
# write the final version to the same basename as the original.
#
#   image = VersionedFile.new('~/image.jpg')
#
#   # finalize the versioned file, preserving the original
#   image.finalize
#
#   # finalize the versioned file, replacing the original
#   image.finalize(:overwrite => true)
#
# The work directory with all other versions will be deleted after the final
# version has been written.
#
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
    raise Errors::SourceDirectoryError, dir: directory if no_dir

    @src_directories.prepend directory_path
  end

  # Returns the constant for the <em>file_operation</em> class. If the
  # constant is not defined, will try to require the source file.
  def self.load(file_operation)
    const = file_operation.split('_').map(&:capitalize).join
    FilePipeline.load_file(file_operation) unless const_defined? const
    const_get 'FileOperations::' + const
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
      raise Errors::SourceFileError,
            file: src_file,
            directories: FilePipeline.source_directories
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
