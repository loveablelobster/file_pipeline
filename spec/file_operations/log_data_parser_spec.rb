# frozen_string_literal: true

module FilePipeline
  module FileOperations
    RSpec.describe LogDataParser do
      subject(:log_data) { described_class.new args }

      let(:data) { { a_key: 'a value' } }
      let(:error) { StandardError.new }
      let(:warning) { 'a warning ' }

      context 'when initialized with nil' do
        let(:args) { nil }

        it { is_expected.to match_array [nil, nil] }
      end

      context 'when initialized with a string' do
        let(:args) { warning }

        it { is_expected.to match_array [[warning], nil] }
      end

      context 'when initialized with an error' do
        let(:args) { error }

        it { is_expected.to match_array [[error], nil] }
      end

      context 'when nitialized with an array with a string and an error' do
        let(:args) { [warning, error] }

        it { is_expected.to match_array [[warning, error], nil] }
      end

      context 'when nitialized with a hash' do
        let(:args) { data }

        it { is_expected.to match_array [nil, data] }
      end

      context 'when nitialized with a hash and a string' do
        let(:args) { [data, warning] }

        it { is_expected.to match_array [[warning], data] }
      end

      context 'when initialized with an error and a hash' do
        let(:args) { [error, data] }

        it { is_expected.to match_array [[error], data] }
      end

      context 'when initialized with an array and a hash' do
        let(:args) { [[warning, error], data] }

        it { is_expected.to match_array [[warning, error], data] }
      end

      context 'when initialized with nil and a hash' do
        let(:args) { [nil, data] }

        it { is_expected.to match_array [nil, data] }
      end

      context 'when initialized with a hash and nil' do
        let(:args) { [data, nil] }

        it { is_expected.to match_array [nil, data] }
      end

      context 'when initialized with a hash and an array' do
        let(:args) { [data, [warning, error]] }

        it { is_expected.to match_array [[warning, error], data] }
      end

      context 'when initialized with a hash, a string, and an error' do
        let(:args) { [data, warning, error] }

        it { is_expected.to match_array [[warning, error], data] }
      end

      context 'when initialized with a string, a hash, and an error' do
        let(:args) { [warning, data, error] }

        it { is_expected.to match_array [[warning, error], data] }
      end

      context 'when initialized with a string, an error, and a hash' do
        let(:args) { [warning, error, data] }

        it { is_expected.to match_array [[warning, error], data] }
      end

      describe '.template' do
        subject { described_class.template }

        it { is_expected.to match_array [[], {}] }
      end
    end
  end
end
