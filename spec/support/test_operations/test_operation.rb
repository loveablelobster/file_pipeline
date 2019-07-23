# frozen_string_literal: true

require 'ruby-vips'

module FilePipeline
  module FileOperations
    # This is an example for what a file operation could look like.
    class TestOperation < FileOperation
      # A Hash with options for the converter.
      # - +:image+: (default: +nil+)
      # - +:height+: image height in pixels for the watermark (default: 768)
      attr_reader :options

      # Returns a new instance.
      def initialize(**opts)
        defaults = {
          image: nil,
          origin_x: 10,
          origin_y: 10
        }
        super(defaults, opts)
      end

      # If the file extension is expected to always be the same (for instance
      # when the purpose of the class is to convert an image to JPEG), replace
      # `super` with the appropriate extension, e.g. `.jpg`. Otherwise, this
      # method can be safely removed.
      def extension(file)
        super
      end

      # required
      # All FileOperation subclasses MUST implement this method, and it MUST
      # take two arguments.
      # An alternative would be to implement the #run method, but then make sure
      # that it takes three arguments: src_file, directory_path, and original
      def operation(src_file, out_file)
        image = Vips::Image.new_from_file(src_file).add_alpha
        watermark = Vips::Image.new_from_file options[:image]
        image.composite2(watermark,
                         :over,
                         x: options[:origin_x],
                         y: options[:origin_y]).write_to_file out_file
      end
    end
  end
end
