# frozen_string_literal: true

RSpec.describe FilePipeline do
  include_context 'shared variables'

  describe '.<<(directory)' do
    context 'when adding a valid directory' do
      subject(:add_dir) { FilePipeline << test_ops }

      before { FilePipeline.source_directories.delete test_ops }

      it do
        expect { add_dir }.to change(FilePipeline, :source_directories)
          .from(a_collection_excluding(test_ops))
          .to a_collection_including test_ops
      end
    end

    context 'when adding a directory that does not exist' do
      subject(:add_dir) { FilePipeline << 'spec/support/nodir' }

      let(:msg) { 'The source directory spec/support/nodir does not exist' }

      it do
        expect { add_dir }
          .to raise_error FilePipeline::Errors::SourceDirectoryError, msg
      end
    end

    context 'when adding a directory that is a file' do
      subject(:add_dir) { FilePipeline << src_file1 }

      let :msg do
        "The source directory #{src_file1} does not exist"
      end

      it do
        expect { add_dir }
          .to raise_error FilePipeline::Errors::SourceDirectoryError, msg
      end
    end
  end

  describe '.load(src_file)' do
    context 'when the source file is found' do
      subject { FilePipeline.load 'ptiff_conversion' }

      it { is_expected.to be FilePipeline::FileOperations::PtiffConversion }
    end

    context 'when the source file is not found' do
      subject(:load_invalid) { FilePipeline.load 'noverter' }

      let :msg do
        starting_with 'The source file noverter.rb was not found. Searched in:'
      end

      it do
        expect { load_invalid }
          .to raise_error FilePipeline::Errors::SourceFileError, msg
      end
    end
  end

  describe '.new_basename(kind)' do
    context 'when kind is :timestamp' do
      subject { FilePipeline.new_basename :timestamp }

      it { is_expected.to be_timestamp }
    end

    context 'when kind is :random' do
      subject { FilePipeline.new_basename :random }

      it { is_expected.to be_uuid }
    end
  end

  describe '.path(dir, filename)' do
    subject { FilePipeline.path 'spec/support', 'example1.jpg' }

    it { is_expected.to eq 'spec/support/example1.jpg' }
  end

  describe '.source_directories' do
    subject { FilePipeline.source_directories }

    it { is_expected.to include default_ops }
  end

  describe '.source_path(file)' do
    context 'when passing a file that exists' do
      subject { FilePipeline.source_path 'ptiff_conversion.rb' }

      it { is_expected.to eq default_ops + '/ptiff_conversion.rb' }
    end

    context 'when passing a file that exists in the custom directory' do
      subject { FilePipeline.source_path('test_operation.rb') }

      before { FilePipeline << test_ops }

      it { is_expected.to eq test_ops + '/test_operation.rb' }
    end

    context 'when passing a file that does not exist' do
      subject { FilePipeline.source_path 'noverter.rb' }

      it { is_expected.to be_nil }
    end
  end
end
