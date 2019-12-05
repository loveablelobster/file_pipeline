# frozen_string_literal: true

require_relative 'versions/history'

module FilePipeline
  # Module that contains classes to work with VersionedFile.
  module Versions
    # Copies the file with path _src_ to <em>/dir/filename</em>.
    def self.copy(src, dir, filename)
      dest = FilePipeline.path(dir, filename)
      FileUtils.cp src, dest
      dest
    end

    # Moves the file with path _src_ to <em>/dir/filename</em>.
    def self.move(src, dir, filename)
      dest = FilePipeline.path(dir, filename)
      FileUtils.mv src, dest
      dest
    end
  end
end
