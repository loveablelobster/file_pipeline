# frozen_string_literal: true

require_relative '../lib/file_pipeline/file_operations'\
                 '/default_operations/scale'

module FilePipeline
  RSpec.describe Pipeline do
    include_context 'shared variables'

    let(:logo) { 'spec/support/logo.png' }
    let(:pipeline) { described_class.new test_ops }
    let(:vfile1) { VersionedFile.new src_file1 }

    let :versions1 do
      contain_exactly(a_timestamp_filename & end_with('.jpg'),
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

    describe '<<(file_operation_instance)' do
      subject(:add_scale_operation) { pipeline << FileOperations::Scale.new }

      it do
        expect { add_scale_operation }.to change(pipeline, :file_operations)
          .from(be_empty).to include an_instance_of(FileOperations::Scale)
      end
    end

    context 'when applying or batch applying' do
      let(:dirs) { [exampledir1, 'spec/support/example2_versions'] }

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
          expect { apply }.to change { vfile1.versions }
            .from(be_empty).to versions1
        end

        it 'creates a final version that is the same as'\
           ' spec/support/full_pipeline.tiff' do
          expect { apply }
            .to change { Digest::MD5.file(vfile1.current) }
            .from(eq(Digest::MD5.file(src_file1)))
            .to eq(Digest::MD5.file('spec/support/full_pipeline.tiff'))
        end
      end

      describe '#batch_apply(*versioned_files)' do
        subject(:batch) { pipeline.batch_apply(vfile1, vfile2) }

        let(:vfile2) { VersionedFile.new src_file2 }

        let :expected_results do
          [
            an_object_having_attributes(versions: versions1),
            an_object_having_attributes(versions: versions2)
          ]
        end

        let :versions2 do
          contain_exactly(a_timestamp_filename & end_with('.tif'),
                          a_timestamp_filename & end_with('.tif'),
                          a_timestamp_filename & end_with('.tiff'),
                          a_timestamp_filename & end_with('.tiff'))
        end

        it { is_expected.to match_array expected_results }

        it do
          expect { batch }.to change { vfile1.versions }
            .from(be_empty).to(versions1)
            .and change { vfile2.versions }.from(be_empty).to versions2
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
end
