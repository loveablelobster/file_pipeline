# frozen_string_literal: true

require 'digest/md5'

require 'file_pipeline/file_operations/default_operations/exif_restoration'

module FilePipeline
  module FileOperations
    # rubocop:disable Metrics/BlockLength
    RSpec.describe ExifRestoration do
      subject :restored do
        described_class.new(skip_tags: %w[JFIFVersion])
                       .run src_file_ptiff, target_dir, src_file1
      end

      include_context 'with directories'
      include_context 'with files'
      include_context 'with tags'

      let(:error) { 'Warning: [Minor] Unrecognized data in IPTC padding' }
      let(:include_tags) { non_writable_tags }
      let(:src_exif) { MultiExiftool.read(src_file_ptiff)[0][0] }

      let :operation do
        an_object_having_attributes name: 'ExifRestoration',
                                    options: operation_options
      end

      let :operation_options do
        include skip_tags: include('JFIFVersion', 'MIMEType')
      end

      it { expect(src_exif).not_to include 'Model' => 'PEN-F' }

      it do
        out_exif = lambda do |out_file|
          result, = MultiExiftool.read out_file
          result.first
        end
        expect(out_exif.call(restored.first)).to include 'Model' => 'PEN-F'
      end

      it { is_expected.to include a_timestamp_filename }

      it { is_expected.to include a_kind_of Results }

      it { expect(restored.last).to have_attributes operation: operation }

      it { expect(restored.last).to have_attributes success: be_truthy }

      it { expect(restored.last).to have_attributes data: include_tags }

      it { expect(restored.last).to have_attributes log: include(error) }
    end
    # rubocop:enable Metrics/BlockLength
  end
end
