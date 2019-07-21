# frozen_string_literal: true

require 'ruby-vips'

module FilePipeline
  module FileOperations
    # Scale instances are FileOperations that will scale an image to a given
    # resolution.
    class Scale < FileOperation
      include Math

      # Returns a new instance.
      # _opts_:
      # - +:width+: target image width in pixels (default: 1024)
      # - +:height+: target image height in pixels (default: 768)
      # - +:method+: a symbol for the method used to calculate the scale factor,
      #   either #scale_by_bounds or #scale_by_pixels (default:
      #   +:scale_by_bounds+)
      def initialize(**opts)
        defaults = {
          width: 1024,
          height: 768,
          method: :scale_by_bounds
        }
        super(defaults, opts)
      end

      # Writes a scaled version of <em>src_file</em> to <em>out_file</em>.
      def operation(src_file, out_file)
        image = Vips::Image.new_from_file src_file
        factor = public_send options[:method], image.size
        image.resize(factor).write_to_file out_file
      end

      # Calculatees the scale factor to scale _dimensions_ (an Array with two
      # elements: width and height) so that it will match the same total pixel
      # count as _width_ multiplied by _height_ given in #options.
      # FIXME: rounding errors may occur.
      def scale_by_pixels(dimensions)
        out_pixels = sqrt(options[:width] * options[:height]).truncate
        src_pixels = sqrt(dimensions[0] * dimensions[1]).truncate
        out_pixels / src_pixels.to_f
      end

      # Calculates the scale factor to scale _dimensions_ (an Array with two
      # elements: width and height) so that it will fit inside the bounds
      # defined by _width_ and _height_ given in #options.
      def scale_by_bounds(dimensions)
        x = options[:width] / dimensions[0].to_f
        y = options[:height] / dimensions[1].to_f
        x * dimensions[1] > options[:height] ? y : x
      end
    end
  end
end
