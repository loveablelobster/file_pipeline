# frozen_string_literal: true

require 'file_pipeline/file_operations'
require 'file_pipeline/file_operations/default_operations/ptiff_conversion'
require 'file_pipeline/file_operations/default_operations/exif_restoration'

RSpec.shared_context 'with operations', shared_context: :metadata do
  let(:converter) { FilePipeline::FileOperations::PtiffConversion.new }
  let(:exif) { FilePipeline::FileOperations::ExifRestoration.new }

  let :operation1a do
    instance_double 'FileOperations::FileOperation',
                    name: 'Op1', options: { x: true },
                    captured_data_tag: :some_data
  end

  let :operation1b do
    instance_double 'FileOperations::FileOperation',
                    name: 'Op1', options: { x: false },
                    captured_data_tag: :some_data
  end

  let :operation2 do
    instance_double 'FileOperations::FileOperation',
                    name: 'Op2', options: {},
                    captured_data_tag: :no_data
  end
end
