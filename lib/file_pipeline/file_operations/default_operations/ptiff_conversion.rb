# frozen_string_literal: true

require 'ruby-vips'

module FilePipeline
  module FileOperations
    # Saves a file to a tiled multi-resolution TIFF, as required by the IIP
    # image server.
    # See https://iipimage.sourceforge.io/documentation/images/ or
    # https://www.loc.gov/preservation/digital/formats/fdd/fdd000237.shtml
    class PtiffConversion < FileOperation
      # Returns a new instance.
      # _opts_:
      # - +:tile+: write a tiled tiff (default: +true+)
      # - +:tile_width+: tile width in pixels (default: 256)
      # - +:tile_height+: tile height in pixels (default: 256)
      def initialize(**opts)
        defaults = {
          tile: true,
          tile_width: 256,
          tile_height: 256
        }
        super(defaults, opts)
        @options[:pyramid] = true
      end

      def extension(_ = nil)
        '.tiff'
      end

      def operation(src_file, out_file)
        image = Vips::Image.new_from_file src_file
        image.tiffsave(out_file, options)
        # Return lof if any
      end
    end
  end
end
