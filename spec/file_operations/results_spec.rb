# frozen_string_literal: true

module FilePipeline
  module FileOperations
    RSpec.describe Results do
      let(:description) { 'an operation' }
      let(:log) { %w[error anothererror yetanotherone] }
      let(:data) { { a: 1, b: 2, c: 3 } }

      subject(:new_instance) { described_class.new description, true, log_data }

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
    end
  end
end
