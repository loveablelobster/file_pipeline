# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module FilePipeline
  module Versions
    # rubocop:disable Metrics/BlockLength
    RSpec.describe History do
      include_context 'with operations'
      include_context 'with results'

      let(:history) { described_class.new }
      let(:version1) { 'version1.txt' }
      let(:version2) { 'version2.txt' }

      before { history[version1] = results1a }

      describe '#[]=' do
        context 'when adding with a new version' do
          subject(:insert_new) { history[version2] = results2 }

          it do
            expect { insert_new }
              .to change { history[version2] }
              .from(be_nil).to include results2
          end

          it do
            expect { insert_new }.not_to(change { history[version1] })
          end
        end

        context 'when adding with an existing version' do
          subject(:insert_again) { history[version1] = results1b }

          it do
            expect { insert_again }
              .to change { history[version1] }
              .from(contain_exactly(results1a))
              .to contain_exactly(results1a, results1b)
          end
        end
      end

      describe '#[]' do
        it { expect(history[version1]).to contain_exactly results1a }
      end

      describe '#captured_data' do
        before do
          history[version1] = results1b
          history[version2] = results2
        end

        it do
          expect(history.captured_data)
            .to contain_exactly [operation1a, results1a.data],
                                [operation1b, results1b.data]
        end
      end

      describe '#captured_data_for(operation_name, **options)' do
        subject { history.captured_data_for(operation, **options) }

        before { history[version1] = results1b }

        let(:operation) { 'Op1' }

        context 'when there is data for the operation' do
          let(:options) { { x: false } }

          it { is_expected.to contain_exactly results1b.data }
        end

        context 'when there is no data for the operation' do
          let(:options) { { y: true } }

          it { is_expected.to be_empty }
        end

        context 'when no modifications have occurred' do
          subject { described_class.new.captured_data_for(operation, **{}) }

          it { is_expected.to be_nil }
        end
      end

      describe '#captured_data_with(tag)' do
        subject { history.captured_data_with(tag) }

        before { history[version2] = results2 }

        context 'when there is data for the tag' do
          let(:tag) { :some_data }

          it { is_expected.to contain_exactly results1a.data }
        end

        context 'when there is no data for the tag' do
          let(:tag) { :bogus_tag }

          it { is_expected.to be_empty }
        end

        context 'when no modifications have occurred' do
          subject { described_class.new.captured_data_with(:some_data) }

          it { is_expected.to be_empty }
        end
      end

      describe '#clear!' do
        it do
          expect { history.clear! }
            .to change(history, :empty?)
            .from(be_falsey).to be_truthy
        end
      end

      describe 'empty?' do
        context 'when no modifications have occurred' do
          it 'returns true' do
            expect(described_class.new).to be_empty
          end
        end

        context 'when modifications have occurred' do
          it 'returns false' do
            expect(history).not_to be_empty
          end
        end
      end

      describe '#log' do
        before do
          history[version1] = results1b
          history[version2] = results2
        end

        it do
          expect(history.log).to contain_exactly\
            [operation1a.name, operation1a.options, results1a.log],
            [operation1b.name, operation1b.options, results1b.log],
            [operation2.name, operation2.options, results2.log]
        end
      end

      describe '#to_a' do
        it do
          expect(history.to_a)
            .to contain_exactly [version1, [results1a]]
        end
      end

      describe '#versions' do
        before do
          history[version1] = results1b
          history[version2] = results2
        end

        it do
          expect(history.versions).to contain_exactly version1, version2
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
# rubocop:enable Metrics/ModuleLength
