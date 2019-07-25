# frozen_string_literal: true

module FilePipeline
  module FileOperations
    RSpec.describe Results do
      subject(:new_instance) { described_class.new description, true, log_data }

      let(:description) { 'an operation' }
      let(:log) { %w[error anothererror yetanotherone] }
      let(:data) { { a: 1, b: 2, c: 3 } }

      context 'when passed log and data with data first' do
        let(:log_data) { [data, log] }

        it { expect(new_instance.log).to match_array(log) }

        it { expect(new_instance.data).to include a: 1, b: 2, c: 3 }
      end

      context 'when passed errors and data with errors first' do
        let(:log_data) { [log, data] }

        it { expect(new_instance.log).to match_array(log) }

        it { expect(new_instance.data).to include a: 1, b: 2, c: 3 }
      end

      context 'when passed data' do
        let(:log_data) { data }

        it { expect(new_instance.log).to be_nil }

        it { expect(new_instance.data).to include a: 1, b: 2, c: 3 }
      end

      context 'when passed errors' do
        let(:log_data) { log }

        it { expect(new_instance.log).to match_array(log) }

        it { expect(new_instance.data).to be_nil }
      end

      context 'when passed an error message' do
        let(:log_data) { 'This is an error' }

        it { expect(new_instance.log).to include 'This is an error' }

        it { expect(new_instance.data).to be_nil }
      end

      context 'when passed an error' do
        let(:log_data) { Errors::FailedModificationError.new }

        it { expect(new_instance.log).to include log_data }

        it { expect(new_instance.data).to be_nil }
      end

      describe '.normalize_log_data(obj)' do
        subject { described_class.normalize_log_data log_data }

        let(:error) { StandardError.new }

        context 'when passed nil' do
          let(:log_data) { nil }

          it { is_expected.to be_nil }
        end

        context 'when passed a string' do
          let(:log_data) { 'a warning' }

          it { is_expected.to match_array [['a warning']] }
        end

        context 'when passed an error' do
          let(:log_data) { error }

          it { is_expected.to match_array [[error]] }
        end

        context 'when passed a message and data' do
          let(:log_data) { ['a warning', data] }

          it { is_expected.to match_array [['a warning'], data] }
        end

        context 'when passed data and an error' do
          let(:log_data) { [data, error] }

          it { is_expected.to match_array [[error], data] }
        end
      end
    end
  end
end
