# frozen_string_literal: true

RSpec.shared_context 'with versioned_files', shared_context: :metadata do
  let(:vfile1) { FilePipeline::VersionedFile.new src_file1 }
  let(:vfile2) { FilePipeline::VersionedFile.new src_file2 }
  let(:vfile3) { FilePipeline::VersionedFile.new src_file3 }
end
