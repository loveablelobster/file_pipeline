# frozen_string_literal: true

require 'file_pipeline/file_operations/default_operations/scale'

# rubocop:disable Metrics/ModuleLength
module FilePipeline
  # rubocop:disable Metrics/BlockLength
  RSpec.describe Pipeline do
    include_context 'with directories'
    include_context 'with files'
    include_context 'with versioned_files'

    let(:pipeline) { described_class.new test_ops }

    let :versions1 do
      contain_exactly(end_with('.jpg'),
                      a_timestamp_filename & end_with('.jpg'),
                      a_timestamp_filename & end_with('.jpg'),
                      a_timestamp_filename & end_with('.tiff'),
                      a_timestamp_filename & end_with('.tiff'))
    end

    context 'when initialized with a source directory' do
      subject(:new_pipeline) { pipeline }

      before do
        FilePipeline.source_directories.delete File.expand_path(test_ops)
      end

      it do
        expect { new_pipeline }.to change(FilePipeline, :source_directories)
          .from(a_collection_excluding(a_string_ending_with(test_ops)))
          .to a_collection_including a_string_ending_with(test_ops)
      end
    end

    context 'when initialized with a block' do
      subject :pipeline_with_ops do
        described_class.new do |ppln|
          ppln.define_operation('scale', width: 1280, height: 1280)
        end
      end

      let :expected_ops do
        include a_kind_of(FileOperations::FileOperation) &
                have_attributes(options: { width: 1280, height: 1280,
                                           method: :scale_by_bounds })
      end

      it do
        expect(pipeline_with_ops)
          .to have_attributes file_operations: expected_ops
      end
    end

    describe '<<(file_operation_instance)' do
      subject(:add_scale_operation) { pipeline << FileOperations::Scale.new }

      it do
        expect { add_scale_operation }.to change(pipeline, :file_operations)
          .from(be_empty).to include an_instance_of(FileOperations::Scale)
      end
    end

    context 'when applying or batch applying' do
      let :dirs do
        [exampledir1,
         'spec/support/example2_versions',
         'spec/support/example3_versions']
      end

      before do
        pipeline.define_operation('scale', width: 1280, height: 1280)
                .define_operation('test_operation', image: logo)
                .define_operation('ptiff_conversion')
                .define_operation('exif_restoration',
                                  skip_tags: %w[JFIFVersion])
      end

      after { dirs.each { |d| FileUtils.rm_r d if File.exist? d } }

      describe '#apply_to(versioned_file)' do
        subject(:apply) { pipeline.apply_to(vfile1) }

        it do
          expect { apply }.to change(vfile1, :versions)
            .from(contain_exactly(vfile1.original)).to versions1
        end

        it 'creates a final version that is the same as'\
           ' spec/support/full_pipeline.tiff'
      end

      describe '#batch_apply(*versioned_files)' do
        subject(:batch) { pipeline.batch_apply [vfile1, vfile2] }

        let :expected_results do
          [
            an_object_having_attributes(versions: versions1),
            an_object_having_attributes(versions: versions2)
          ]
        end

        let :versions2 do
          contain_exactly(end_with('.tif'),
                          a_timestamp_filename & end_with('.tif'),
                          a_timestamp_filename & end_with('.tif'),
                          a_timestamp_filename & end_with('.tiff'),
                          a_timestamp_filename & end_with('.tiff'))
        end

        it { is_expected.to match_array expected_results }

        it do
          expect { batch }.to change(vfile1, :versions)
            .from(contain_exactly(vfile1.original)).to(versions1)
            .and change(vfile2, :versions)
            .from(contain_exactly(vfile2.original)).to versions2
        end
      end

      context 'when applied to a file that is not supported' do
        subject(:apply) { pipeline.apply_to(vfile3) }

        it do
          expect { apply }.to raise_error Errors::FailedModificationError
        end
      end

      context 'when batch applied to files including one unsupported' do
        subject(:batch) { pipeline.batch_apply [vfile1, vfile3, vfile2] }

        it do
          expect { batch }.to raise_error Errors::FailedModificationError
        end
      end
    end

    describe '#define_operation(file_operation, options)' do
      subject(:define_ptiff_conversion) do
        pipeline.define_operation 'ptiff_conversion',
                                  tile_width: 128, tile_height: 128
      end

      let(:opts) { a_hash_including tile_width: 128, tile_height: 128 }

      it do
        expect { define_ptiff_conversion }
          .to change(pipeline, :file_operations)
          .from(be_empty)
          .to include(a_kind_of(FileOperations::FileOperation) &
                      have_attributes(options: opts))
      end
    end

    describe '#empty?' do
      subject { pipeline.empty? }

      context 'when no operations have been added' do
        it { is_expected.to be_truthy }
      end

      context 'when operation have been added' do
        before { pipeline << FileOperations::Scale.new }

        it { is_expected.to be_falsey }
      end
    end

    describe '#run(operation, versioned_file)' do
      subject :scale do
        pipeline.run(pipeline.file_operations[0], vfile1)
      end

      before { pipeline.define_operation 'scale', width: 128, height: 128 }

      after { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

      it do
        expect(Vips::Image.new_from_file(scale.current))
          .to have_attributes width: 128, height: 128
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength
