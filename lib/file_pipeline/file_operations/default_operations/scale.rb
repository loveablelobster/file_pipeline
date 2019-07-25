# frozen_string_literal: true

require 'ruby-vips'

module FilePipeline
  module FileOperations
    # Scale instances are FileOperations that will scale an image to a given
    # resolution.
    #
    # ==== Caveats
    #
    # This will scale images smaller than the given width and height up.
    class Scale < FileOperation
      include Math

      # :args: options
      #
      # Returns a new instance.
      #
      # ==== Options
      #
      # * +:width+ - The target image width in pixels (_default_ 1024).
      # * +:height+ - The target image height in pixels (_default_ 768).
      # * +:method+ - A symbol for the method used to calculate the scale:
      #   factor.
      #   * +:scale_by_bounds+ (_default_) - see #scale_by_bounds.
      #   * +:scale_by_pixels+ - See #scale_by_pixels.
      def initialize(**opts)
        defaults = {
          width: 1024,
          height: 768,
          method: :scale_by_bounds
        }
        super(defaults, opts)
      end

      # :args: src_file, out_file
      #
      # Writes a scaled version of <tt>src_file</tt> to <tt>out_file</tt>.
      def operation(*args)
        src_file, out_file = args
        image = Vips::Image.new_from_file src_file
        factor = public_send options[:method], image.size
        image.resize(factor).write_to_file out_file
      end

      # Calculatees the scale factor to scale +dimensions+ (an array with image
      # width and height in pixels) so that it will match the same total pixel
      # count as +:width+ multiplied by +:height+ given in #options.
      #
      # *Warning*: rounding errors may occur.
      #
      #--
      # FIXME: avoid rounding errors.
      #++
      def scale_by_pixels(dimensions)
        out_pixels = sqrt(options[:width] * options[:height]).truncate
        src_pixels = sqrt(dimensions[0] * dimensions[1]).truncate
        out_pixels / src_pixels.to_f
      end

      # Calculates the scale factor to scale +dimensions+ (an array with image
      # width and height in pixels) so that it will fit inside the bounds
      # defined by +:width+ and +:height+ given in #options.
      def scale_by_bounds(dimensions)
        x = options[:width] / dimensions[0].to_f
        y = options[:height] / dimensions[1].to_f
        x * dimensions[1] > options[:height] ? y : x
      end
    end
  end
end
