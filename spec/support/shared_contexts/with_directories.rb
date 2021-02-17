# frozen_string_literal: true

RSpec.shared_context 'with directories', shared_context: :metadata do
  # Directories
  let :default_ops do
    File.expand_path 'lib/file_pipeline/file_operations/default_operations'
  end

  let(:test_ops) { File.expand_path 'spec/support/test_operations' }
  let(:target_dir) { File.expand_path 'spec/support/test_directory' }
  let(:exampledir1) { 'spec/support/example1_versions' }
end
