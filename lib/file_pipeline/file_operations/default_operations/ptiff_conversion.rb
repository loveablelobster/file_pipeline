# frozen_string_literal: true

require 'ruby-vips'

module FilePipeline
  module FileOperations
    # Saves a file to a <em>tiled multi-resolution TIFF</em> ('pyramid'), as
    # required by e.g. the IIP image server.
    #
    # See https://iipimage.sourceforge.io/documentation/images/ or
    # https://www.loc.gov/preservation/digital/formats/fdd/fdd000237.shtml
    # for more information on the format.
    class PtiffConversion < FileOperation
      # :args: options
      #
      # Returns a new instance.
      #
      # ==== Options
      #
      # * +:tile+ - Writes a tiled _TIFF_ (_default_ +true+)
      # * +:tile_width+: Tile width in pixels (_default_ +256+)
      # * +:tile_height+: Tile height in pixels (_default_ +256+)
      def initialize(**opts)
        defaults = {
          tile: true,
          tile_width: 256,
          tile_height: 256
        }
        super(defaults, opts)
        @options[:pyramid] = true
      end

      # :args: src_file, out_file
      #
      # Writes a pyramid tiff version of <tt>src_file</tt> to <tt>out_file</tt>.
      #
      # ==== Arguments
      #
      # * <tt>src_file</tt> - Path for the file the operation will use as the
      #   basis for the new version it will create.
      # * <tt>out_file</tt> - Path the file created by the operation will be
      #   written to.
      def operation(*args)
        src_file, out_file = args
        image = Vips::Image.new_from_file src_file
        image.tiffsave(out_file, options)
        # Return lof if any
      end

      # Returns <tt>'.tiff'</tt> (all files created by #operation will be _TIFF_
      # files).
      def target_extension
        '.tiff'
      end
    end
  end
end
