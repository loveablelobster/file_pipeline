# frozen_string_literal: true

RSpec.shared_context 'with results', shared_context: :metadata do
  let :results1a do
    instance_double('FileOperations::Results',
                    operation: operation1a, success: true,
                    log: ['warning1'], data: { a: 1, b: 2 })
  end

  let :results1b do
    instance_double('FileOperations::Results',
                    operation: operation1b, success: true,
                    log: ['warning2'], data: { c: 3, d: 4 })
  end

  let :results2 do
    instance_double('FileOperations::Results',
                    operation: operation2, succuess: true,
                    log: %w[info1 info2], data: nil)
  end
end
