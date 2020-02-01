# frozen_string_literal: true

require_relative '../../../lib/file_pipeline/file_operations'\
                 '/default_operations/ptiff_conversion'

module FilePipeline
  module FileOperations
    RSpec.describe PtiffConversion do
      include_context 'with variables'

      subject :pyramid do
        described_class
          .new
          .run src_file1, target_dir
      end

      it do
        expect(Digest::MD5.file(pyramid.first))
          .not_to eq(Digest::MD5.file(src_file1))
      end

      it 'converts the file to a multiresolution (pyramid) tiff'
    end
  end
end
