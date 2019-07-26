# frozen_string_literal: true

module FilePipeline
  module FileOperations
    RSpec.describe LogDataParser do
      subject(:log_data_first) { log_data[0] }
      subject(:log_data_last) { log_data[1] }

      let(:log_data) { described_class.new args }

      let(:data) { { a_key: 'a value' } }
      let(:error) { StandardError.new }
      let(:warning) { 'a warning '}

      context 'when initialized with nil' do
        let(:args) { nil }

        it { expect(log_data_first).to be_nil }

        it { expect(log_data[1]).to be_nil }
      end

      context 'when initialized with a string' do
        let(:args) { warning }

        it { expect(log_data_first).to match_array [warning] }

        it { expect(log_data_last).to be_nil }
      end

      context 'when initialized with an error' do
        let(:args) { error }

        it { expect(log_data_first).to match_array [error] }

        it { expect(log_data_last).to be_nil }
      end

      context 'when nitialized with an array with a string and an error' do
        let(:args) { [warning, error] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be_nil }
      end

      context 'when nitialized with a hash' do
        let(:args) { data }

        it { expect(log_data_first).to be_nil }

        it { expect(log_data_last).to be data }
      end

      context 'when nitialized with a hash and a string' do
        let(:args) { [data, warning] }

        it { expect(log_data_first).to match_array [warning] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed an error and a hash' do
        let(:args) { [error, data] }

        it { expect(log_data_first).to match_array [error] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed an array and a hash' do
        let(:args) { [[warning, error], data] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed a hash and an array' do
        let(:args) { [data, [warning, error]] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed a hash, a string, and an error' do
        let(:args) { [data, warning, error] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed a string, a hash, and an error' do
        let(:args) { [warning, data, error] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be data }
      end

      context 'when passed a string, an error, and a hash' do
        let(:args) { [warning, error, data] }

        it { expect(log_data_first).to match_array [warning, error] }

        it { expect(log_data_last).to be data }
      end
    end
  end
end
