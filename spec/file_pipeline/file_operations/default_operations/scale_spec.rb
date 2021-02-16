# frozen_string_literal: true

require 'file_pipeline/file_operations/default_operations/scale'

module FilePipeline
  module FileOperations
    RSpec.describe Scale do
      include_context 'with variables'

      context 'when scaling by bounds' do
        subject :scale do
          described_class
            .new(width: 1280, height: 960, method: :scale_by_bounds)
            .run src_file1, target_dir
        end

        it do
          expect(Vips::Image.new_from_file(scale.first))
            .to have_attributes width: 960, height: 960
        end
      end

      context 'when scaling by pixels' do
        subject :scale do
          described_class
            .new(width: 1280, height: 960, method: :scale_by_pixels)
            .run src_file1, target_dir
        end

        it do
          expect(Vips::Image.new_from_file(scale.first))
            .to have_attributes width: 1108, height: 1108
        end
      end
    end
  end
end
