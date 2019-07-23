# frozen_string_literal: true

module FilePipeline
  module FileOperations
    RSpec.describe FileOperation do
      describe '.store_error(e, log_data)' do
        subject(:stored) { described_class.store_error error, log_data }

        let(:log) { %w[error anothererror] }
        let(:data) { { a: 1, b: 2, c: 3 } }
        let(:error) { StandardError.new }
        let(:exp_log) { ['error', 'anothererror', error] }

        context 'when passed log and data with data first' do
          let(:log_data) { [data, log] }

          it { is_expected.to match_array [exp_log, data] }
        end

        context 'when passed errors and data with errors first' do
          let(:log_data) { [log, data] }

          it { is_expected.to match_array [exp_log, data] }
        end

        context 'when passed data' do
          let(:log_data) { data }

          it { is_expected.to match_array [[error], data] }
        end

        context 'when passed errors' do
          let(:log_data) { log }

          it { is_expected.to match_array [exp_log] }
        end

        context 'when passed an error message' do
          let(:log_data) { 'This is an error' }

          it { is_expected.to match_array [['This is an error', error]] }
        end

        context 'when passed an error' do
          let(:log_data) { fme }

          let(:fme) { Errors::FailedModificationError.new }

          it { is_expected.to match_array [[fme, error]] }
        end

        context 'when passed nil' do
          let(:log_data) { nil }

          it { is_expected.to match_array [error] }
        end
      end
    end
  end
end
