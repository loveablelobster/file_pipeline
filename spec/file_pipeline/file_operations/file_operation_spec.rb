# frozen_string_literal: true

module FilePipeline
  # rubocop:disable Metrics/ModuleLength
  module FileOperations
    # rubocop:disable Metrics/BlockLength
    RSpec.describe FileOperation do
      include_context 'with directories'
      include_context 'with files'

      let(:file_operation) { described_class.new(opts) }
      let(:opts) { {} }

      describe 'captured_data_tag' do
        subject { file_operation.captured_data_tag }

        it { is_expected.to be CapturedDataTags::NO_DATA }
      end

      describe '#extension(file)' do
        subject(:extension) { file_operation.extension src_file1 }

        it 'returns the extension of the file passed as a parameter' do
          expect(extension).to eq File.extname(src_file1)
        end
      end

      describe '#failure(log_data)' do
        subject(:results) { file_operation.failure }

        it 'returns a Results object' do
          expect(results).to have_attributes operation: file_operation,
                                             success: false
        end
      end

      describe '#modifies?' do
        subject { file_operation.modifies? }

        it { is_expected.to be_truthy }
      end

      describe '#name' do
        subject { file_operation.name }

        it { is_expected.to eq 'FileOperation' }
      end

      describe '#operation' do
        subject(:operation) { file_operation.operation }

        it 'raises an error' do
          expect { operation }.to raise_error RuntimeError, 'not implemented'
        end
      end

      describe '#options' do
        subject(:options) { file_operation.options }

        it 'returns any options with which the instance was initialized' do
          expect(options).to eq opts
        end
      end

      describe '#results(success, log_data)' do
        subject(:results) { file_operation.results success }

        context 'when the operation was successful' do
          let(:success) { true }

          it 'returns a Results object' do
            expect(results).to have_attributes operation: file_operation,
                                               success: true
          end
        end

        context 'when the operation was not successful' do
          let(:success) { false }

          it 'returns a Results object' do
            expect(results).to have_attributes operation: file_operation,
                                               success: false
          end
        end
      end

      describe '#run(src_file, directory, original)' do
        subject(:result) { file_operation.run src_file1, exampledir1 }

        let :error do
          a_kind_of(RuntimeError).and have_attributes message: 'not implemented'
        end

        it 'returns the version file and a result object' do
          expect(result).to contain_exactly \
            a_string_starting_with(exampledir1),
            an_object_having_attributes(operation: file_operation,
                                        success: false,
                                        log: contain_exactly(error))
        end
      end

      describe '#success(log_data)' do
        subject(:results) { file_operation.success }

        it 'returns a Results object' do
          expect(results).to have_attributes operation: file_operation,
                                             success: true
        end
      end

      describe '#target(directory, extension, kind)' do
        subject(:target) { file_operation.target exampledir1, extension, kind }

        let(:extension) { '.jpg' }

        context 'with timestamp filenames' do
          let(:kind) { :timestamp }

          it 'returns a filepath with directory and a timestamp plus extension'\
             ' as basename' do
            expect(target).to be_a_timestamp_filename.and start_with exampledir1
          end
        end

        context 'with random filenames' do
          let(:kind) { :random }

          it 'returns a filepath with directory and a UUID plus extension'\
             ' as basename' do
            expect(target)
              .to be_a_randomized_filename.and start_with exampledir1
          end
        end
      end

      describe '#target_extension' do
        subject { file_operation.target_extension }

        it { is_expected.to be_nil }
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/ModuleLength
end
