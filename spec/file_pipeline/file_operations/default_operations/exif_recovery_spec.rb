# frozen_string_literal: true

require 'file_pipeline/file_operations/default_operations/exif_recovery'

module FilePipeline
  module FileOperations
    RSpec.describe ExifRecovery do
      subject :recovered do
        described_class.new(skip_tags: %w[JFIFVersion])
                       .run src_file_ptiff, target_dir, src_file1
      end

      include_context 'with directories'
      include_context 'with files'
      include_context 'with tags'

      let(:include_tags) { non_writable_tags }

      let :operation do
        an_object_having_attributes name: 'ExifRecovery',
                                    options: operation_options
      end

      let :operation_options do
        include skip_tags: include('JFIFVersion', 'MIMEType')
      end

      it 'returns no file' do
        expect(recovered.first).to be_nil
      end

      it { is_expected.to include a_kind_of Results }

      it { expect(recovered.last).to have_attributes operation: operation }

      it { expect(recovered.last).to have_attributes success: be_truthy }

      it { expect(recovered.last).to have_attributes data: include_tags }
    end
  end
end
