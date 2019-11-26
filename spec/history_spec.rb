# frozen_string_literal: true

module FilePipeline
  RSpec.describe History do
    let(:history) { described_class.new }
    let(:version1) { 'version1.txt' }
    let(:version2) { 'version2.txt' }

    let :operation1a do
      double 'operation', name: 'Op1', options: { x: true },
        captured_data_tag: :some_data
    end

    let :operation1b do
      double 'operation', name: 'Op1', options: { x: false },
        captured_data_tag: :some_data
    end

    let :operation2 do
      double 'operation', name: 'Op2', options: {},
        captured_data_tag: :no_data
    end

    let :results1a do
      double('FileOperations::Results',
             operation: operation1a,
             success: true, log: ['warning1'], data: { a: 1, b: 2 })
    end

    let :results1b do
      double('FileOperations::Results',
             operation: operation1b,
             success: true, log: ['warning2'], data: { c: 3, d: 4 })
    end

    let :results2 do
      double('FileOperations::Results',
             operation: operation2,
             succuess: true, log: ['info1', 'info2'], data: nil)
    end
    
    before { history[version1] = results1a }
    
    describe '#[]=' do
      context 'when adding with a new version' do
        subject(:insert_new) { history[version2] = results2 }

        it do
          expect { insert_new }.to change { history[version2] }
                               .from(be_nil).to include results2
        end

        it do
          expect { insert_new }.not_to change { history[version1] }
        end
      end

      context 'when adding with an existing version' do
        subject(:insert_again) { history[version1] = results1b }

        it do
          expect { insert_again }.to change { history[version1] }
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
      before { history[version1] = results1b }

      it do
        expect(history.captured_data_for('Op1', x: false))
          .to contain_exactly results1b.data
      end
    end

    describe '#captured_data_with(tag)' do
      before { history[version2] = results2 }

      it do
        expect(history.captured_data_with(:some_data))
          .to contain_exactly results1a.data
      end
    end

    describe '#log' do
      before do
        history[version1] = results1b
        history[version2] = results2
      end

      it do
        expect(history.log)
          .to contain_exactly [operation1a.name,
                               operation1a.options,
                               results1a.log],
                              [operation1b.name,
                               operation1b.options,
                               results1b.log],
                              [operation2.name,
                               operation2.options,
                               results2.log]
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
end
