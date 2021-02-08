# frozen_string_literal: true

module FilePipeline
  # rubocop:disable Metrics/ModuleLength
  module Versions
    # rubocop:disable Metrics/BlockLength
    RSpec.describe Validator do
      include_context 'with variables'

      let :validator do
        described_class.new version_info, exampledir1, src_file1
      end

      let(:file) { "#{exampledir1}/version1.jpg" }
      let(:results) { instance_double FileOperations::Results }
      let(:version_info) { [file, results] }

      let :versioned_file do
        instance_double VersionedFile,
                        directory: exampledir1,
                        original: src_file1
      end

      before do
        allow(File).to receive(:dirname).with(file).and_return exampledir1
        allow(File).to receive(:exist?).with(file).and_return true
        allow(results).to receive(:failure).and_return false
      end

      describe '.[]' do
        subject(:validation) { described_class[version_info, versioned_file] }

        context 'with a file only' do
          let(:version_info) { file }

          it 'returns a Array with the file and nil' do
            expect(validation).to contain_exactly file, nil
          end
        end

        context 'with a file and a results object' do
          it 'returns an Array with the file and results object' do
            expect(validation).to contain_exactly file, results
          end
        end

        context 'with a results object only' do
          let(:file) { nil }

          it 'returns and Array with nil and the results object' do
            expect(validation).to contain_exactly nil, results
          end
        end
      end

      describe '#file' do
        subject(:expected_filepath) { validator.file }

        context 'with a file' do
          it 'returns the filepath for the version' do
            expect(expected_filepath).to eq file
          end
        end

        context 'without a file' do
          let(:file) { nil }

          it { is_expected.to be_nil }
        end
      end

      describe '#info' do
        subject(:expected_info) { validator.info }

        context 'with a results object' do
          it 'returns the results object' do
            expect(expected_info).to be results
          end
        end

        context 'without a results object' do
          let(:version_info) { file }

          it { is_expected.to be_nil }
        end
      end

      describe '#unmodified?' do
        subject { validator.unmodified? }

        context 'when there is no new version file' do
          let(:file) { nil }

          it { is_expected.to be_truthy }
        end

        context 'when there is a new version file' do
          it { is_expected.to be_falsey }
        end
      end

      describe '#validate_directory' do
        subject(:validate_directory) { validator.validate_directory }

        context 'when it is in the working directory' do
          it { is_expected.to be validator }
        end

        context 'when it is not in the working directory' do
          before do
            allow(File).to receive(:dirname).with(file).and_return target_dir
          end

          it 'raises MisplacedVersionFileError' do
            expect { validate_directory }
              .to raise_error Errors::MisplacedVersionFileError
          end
        end
      end

      describe '#validate_file' do
        subject(:validate_file) { validator.validate_file }

        context 'when it exists' do
          it { is_expected.to be validator }
        end

        context 'when it does not exist' do
          before do
            allow(File).to receive(:exist?).with(file).and_return false
          end

          it 'raises MissingVersionFileError' do
            expect { validate_file }
              .to raise_error Errors::MissingVersionFileError
          end
        end
      end

      describe '#validate_info' do
        subject(:validate_info) { validator.validate_info }

        context 'when the file operation succeeded' do
          it { is_expected.to be validator }
        end

        context 'when the file operation failed' do
          before do
            allow(results).to receive(:failure).and_return true
          end

          it 'raises FailedModificationError' do
            expect { validate_info }
              .to raise_error Errors::FailedModificationError
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/ModuleLength
end
