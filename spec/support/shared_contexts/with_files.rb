# frozen_string_literal: true

RSpec.shared_context 'with files', shared_context: :metadata do
  let(:logo) { 'spec/support/logo.png' }
  let(:src_file1) { File.expand_path 'spec/support/example1.jpg' }
  let(:src_file2) { File.expand_path 'spec/support/example2.tif' }
  let(:src_file3) { File.expand_path 'spec/support/example3.jp2' }
  let(:src_file_ptiff) { 'spec/support/pyramid.tiff' }
end
