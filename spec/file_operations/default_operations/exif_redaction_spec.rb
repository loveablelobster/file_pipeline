# frozen_string_literal: true

require 'digest/md5'

require_relative '../../../lib/file_pipeline/file_operations'\
                 '/default_operations/exif_redaction'

module FilePipeline
  module FileOperations
    RSpec.describe ExifRedaction do
      include_context 'with variables'

      subject :redacted do
        described_class.new(redact_tags: tags)
                       .run src_file1, target_dir
      end

      let(:tags) { %w[Make Model Lens LensInfo CreatorTool Software] }
      let(:src_exif) { MultiExiftool.read(src_file1)[0][0] }

      let :deleted_values do
        include 'Make' => 'OLYMPUS CORPORATION', 'Model' => 'PEN-F',
                'Lens' => 'LEICA DG MACRO-ELMARIT 45/F2.8',
                'LensInfo' => '45mm f/2.8',
                'Software' => 'Flying Meat Acorn 6.0.3',
                'CreatorTool' => 'Flying Meat Acorn 6.0.3'
      end

      let :operation do
        an_object_having_attributes name: 'ExifRedaction',
                                    options: operation_options
      end

      let :operation_options do
        include redact_tags: match_array(tags)
      end

      it { expect(src_exif).to include(*tags) }

      it do
        out_exif = lambda do |out_file|
          result, = MultiExiftool.read out_file
          result.first
        end
        expect(out_exif.call(redacted.first)).not_to include(*tags)
      end

      it { is_expected.to include a_timestamp_filename }

      it { is_expected.to include a_kind_of Results }

      it { expect(redacted.last).to have_attributes operation: operation }

      it { expect(redacted.last).to have_attributes success: be_truthy }

      it { expect(redacted.last.data).to include metadata: deleted_values }

      it { expect(redacted.last.log).to be_nil }
    end
  end
end
