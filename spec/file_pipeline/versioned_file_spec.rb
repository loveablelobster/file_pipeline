# frozen_string_literal: true

require 'ostruct'

# rubocop:disable Metrics/ModuleLength
module FilePipeline
  # rubocop:disable Metrics/BlockLength
  RSpec.describe VersionedFile do
    include_context 'with directories'
    include_context 'with files'
    include_context 'with operations'
    include_context 'with tags'

    let :versioned_file do
      described_class.new 'spec/support/example1.jpg',
                          target_suffix: 'converted'
    end

    before { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

    after { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

    describe '#<<' do
      before { versioned_file.directory }

      context 'when an operation returns a failure status' do
        subject(:add_failure) { versioned_file << [nil, broken_results] }

        let :broken_results do
          info = OpenStruct.new(name: 'Kaputt', options: { cannot_work: true })
          FileOperations::Results.new info, false, 'Error: Something went wrong'
        end

        it do
          expect { add_failure }
            .to raise_error Errors::FailedModificationError
        end
      end

      context 'when file is in the working directory' do
        subject(:add_version) { versioned_file << stored }

        before { FileUtils.cp src_file_ptiff, stored }

        let(:stored) { "#{exampledir1}/pyramid.tiff" }

        it do
          expect { add_version }.to change(versioned_file, :versions)
            .from(a_collection_excluding(stored)).to include stored
        end

        it do
          expect { add_version }.to change(versioned_file, :current)
            .from('spec/support/example1.jpg').to(stored)
        end
      end

      context 'when file is not in the working directory' do
        subject :add_version do
          versioned_file << 'spec/support/pyramid_copy.tiff'
        end

        let(:version) { 'spec/support/example1_versions/pyramid_copy.tiff' }

        before do
          FileUtils.cp 'spec/support/pyramid.tiff',
                       'spec/support/pyramid_copy.tiff'
        end

        it do
          expect { add_version }
            .to raise_error Errors::MisplacedVersionFileError,
                            'File pyramid_copy.tiff was expected in'\
                            ' spec/support/example1_versions, but was in'\
                            ' spec/support.'
        end
      end

      context 'when the operation did not modify, there is no version file' do
        subject :no_modification do
          versioned_file << [nil, no_mod_results]
        end

        let :no_mod_results do
          info = OpenStruct.new(name: 'ChangeNot', options: { mod: false })
          FileOperations::Results.new info, true, 'some log'
        end

        it do
          expect { no_modification }.not_to change(versioned_file, :current)
        end

        it 'adds the results' do
          expect { no_modification }.to change(versioned_file, :log)
        end
      end
    end

    describe '#basename' do
      subject { versioned_file.basename }

      it { is_expected.to eq 'example1' }
    end

    context 'when returning captured data or logs' do
      before do
        versioned_file
          .modify { |src, path| converter.run src, path }
          .modify { |src, path, orig| exif.run src, path, orig }
      end

      describe '#captured_data' do
        subject(:captured) { versioned_file.captured_data }

        let :exif_description do
          an_object_having_attributes(name: 'ExifRestoration')
        end

        let :restoration_capture do
          a_collection_including exif_description,
                                 non_writable_tags
        end

        it do
          expect(captured)
            .to include restoration_capture
        end
      end

      describe '#captured_data_for(operation_name)' do
        subject do
          versioned_file.captured_data_for 'ExifRestoration', skip_tags: tags
        end

        it { is_expected.to include non_writable_tags }
      end

      describe '#log' do
        subject(:log) { versioned_file.log }

        let :warning do
          msg = 'Warning: [Minor] Unrecognized data in IPTC padding'
          a_collection_including msg
        end

        let(:opts) { an_instance_of(Hash).and include(skip_tags: tags) }

        it do
          expect(log)
            .to include a_collection_including('ExifRestoration', opts, warning)
        end
      end
    end

    describe '#captured_data_with(tag)' do
      subject do
        tag = FileOperations::CapturedDataTags::DROPPED_EXIF_DATA
        versioned_file.captured_data_with(tag)
      end

      context 'when no modifications have occurred' do
        it { is_expected.to be_empty }
      end

      context 'when modifications have occurred' do
        before do
          pipeline = Pipeline.new do |ppln|
            ppln.define_operation('ptiff_conversion')
            ppln.define_operation('exif_restoration')
            ppln.define_operation('exif_redaction',
                                  redact_tags: %w[CreatorTool Software])
          end

          pipeline.apply_to versioned_file
        end

        let(:include_expected_values) { include non_writable_tags }

        after { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

        it { is_expected.to include_expected_values }
      end
    end

    describe '#changed?' do
      subject { versioned_file.changed? }

      context 'when it has been changed' do
        before { versioned_file.touch }

        it { is_expected.to be_truthy }
      end

      context 'when it has not been changed' do
        it { is_expected.to be_falsey }
      end
    end

    describe '#clone' do
      subject(:clone) { versioned_file.clone }

      let(:version) do
        a_timestamp_filename & ending_with('.jpg')
      end

      it do
        expect { clone }.to change(versioned_file, :versions)
          .from(a_collection_excluding(version))
          .to include version
      end

      it 'creates a directory with the name <filename>_versions' do
        expect { clone }.to change { Dir.children 'spec/support' }
          .from(an_array_excluding(a_string_ending_with('_versions')))
          .to include a_string_ending_with('_versions')
      end

      it do
        expect { clone }.to change(versioned_file, :current)
          .from('spec/support/example1.jpg')
          .to(a_timestamp_filename & ending_with('.jpg'))
      end
    end

    describe '#current' do
      subject { versioned_file.current }

      context 'when no modifications or cloning have occurred' do
        it { is_expected.to be versioned_file.original }
      end

      context 'when modifications or cloning have occurred' do
        before { versioned_file.clone }

        it { is_expected.to be_a_timestamp_filename }
      end
    end

    describe '#current_extension' do
      subject { versioned_file.current_extension }

      context 'when no conversions have occurred' do
        it { is_expected.to eq File.extname(versioned_file.original) }
      end

      context 'when conversions have occurred' do
        before { versioned_file.modify { |src, path| converter.run src, path } }

        it { is_expected.not_to eq File.extname(versioned_file.original) }

        it { is_expected.to eq '.tiff' }
      end
    end

    describe '#directory' do
      subject(:get_directory) { versioned_file.directory }

      it { expect(get_directory).to eq exampledir1 }

      context 'when the directory has not been created' do
        it 'creates a directory with the name <filename>_versions' do
          expect { get_directory }.to change { Dir.children 'spec/support' }
            .from(an_array_excluding(a_string_ending_with('_versions')))
            .to include a_string_ending_with('_versions')
        end
      end
    end

    describe '#finalize' do
      context 'when preserving the original' do
        subject(:finalize) { versioned_file.finalize }

        before do
          versioned_file.modify { |src, path| converter.run src, path }
        end

        after { FileUtils.rm 'spec/support/example1_converted.tiff' }

        it do
          expect { finalize }.to change { Dir.children 'spec/support' }
            .from(an_array_excluding('example1_converted.tiff'))
            .to(including('example1_converted.tiff'))
        end

        it do
          expect { finalize }.to change { Dir.children 'spec/support' }
            .from(including('example1_versions'))
            .to(an_array_excluding('example1_versions'))
        end

        it do
          expect { finalize }.to change(versioned_file, :versions)
            .from(including(a_timestamp_filename)).to be_empty
        end
      end

      context 'when overwriting the original' do
        subject :finalize do
          described_class.new(work_copy)
                         .modify { |src, path| converter.run src, path }
                         .finalize overwrite: true
        end

        let(:work_copy) { 'spec/support/example_copy.jpg' }

        before { FileUtils.cp 'spec/support/example1.jpg', work_copy }

        after do
          FileUtils.rm work_copy if File.exist? work_copy
          conv = 'spec/support/example_copy.tiff'
          FileUtils.rm conv if File.exist? conv
        end

        it do
          expect { finalize }.to change { Dir.children 'spec/support' }
            .from(including('example_copy.jpg'))
            .to(an_array_excluding('example_copy.jpg'))
        end

        it do
          expect { finalize }.to change { Dir.children 'spec/support' }
            .from(an_array_excluding('example_copy.tiff'))
            .to(including('example_copy.tiff'))
        end
      end
    end

    describe '#history' do
      subject { versioned_file.history }

      context 'when no modifications have occurred' do
        it { is_expected.to contain_exactly [versioned_file.original, []] }
      end

      context 'when modifications have occurred' do
        subject(:history) { versioned_file.history }

        before do
          versioned_file.modify { |src, path| converter.run src, path }
        end

        it do
          expect(history)
            .to have_attributes(versions: include(a_timestamp_filename))
          # and an instance of results
        end
      end
    end

    describe '#metadata' do
      subject :file_metadata do
        versioned_file.metadata(for_version: version)
                      .delete_if { |k, _| k == 'FileAccessDate' }
      end

      let :original_exif do
        MultiExiftool.read(src_file1)[0][0]
                     .to_h
                     .delete_if { |k, _| k == 'FileAccessDate' }
      end

      let :final_exif do
        lambda do
          result, = MultiExiftool.read versioned_file.current
          exif_hash = result.first.to_h.transform_values do |val|
            next val unless File.exist? val.to_s

            File.expand_path val
          end
          exif_hash.delete_if { |k, _| k == 'FileAccessDate' }
        end
      end

      context 'when no modifications have occurred' do
        let(:version) { :current }

        it { expect(file_metadata).to eq original_exif }
      end

      context 'when modifications have occurred' do
        before { versioned_file.modify { |src, path| converter.run src, path } }

        after { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

        context 'when accessing the current version' do
          let(:version) { :current }

          it { expect(file_metadata).to eq final_exif.call }
        end

        context 'when accessing the original version' do
          let(:version) { :original }

          it { expect(file_metadata).to eq original_exif }
        end

        context 'when accession an arbitrary version by name' do
          let(:version) { versioned_file.current }

          it { expect(file_metadata).to eq final_exif.call }
        end
      end
    end

    describe '#modify' do
      context 'when applying a converter' do
        subject :modify do
          versioned_file.modify { |src, path| converter.run src, path }
        end

        let(:version) do
          a_timestamp_filename & ending_with('.tiff')
        end

        it do
          expect { modify }.to change(versioned_file, :versions)
            .from(a_collection_excluding(version))
            .to include version
        end

        it 'creates a directory with the name <filename>_versions' do
          expect { modify }.to change { Dir.children 'spec/support' }
            .from(an_array_excluding(a_string_ending_with('_versions')))
            .to include a_string_ending_with('_versions')
        end

        it do
          expect { modify }.to change(versioned_file, :current)
            .from('spec/support/example1.jpg')
            .to(a_timestamp_filename & ending_with('.tiff'))
        end
      end

      context 'when not returning a file from the block' do
        subject(:not_modify) { versioned_file.modify { 'this is not a file' } }

        it do
          expect { not_modify }
            .to raise_error Errors::MissingVersionFileError,
                            'File missing for version \'this is not a file\''
        end
      end
    end

    describe '#original' do
      subject { versioned_file.original }

      it { is_expected.to eq 'spec/support/example1.jpg' }
    end

    describe '#recovered_metadata' do
      subject { versioned_file.recovered_metadata }

      context 'when no modifications have occurred' do
        it { is_expected.to be_nil }
      end

      context 'when modifications have occurred' do
        before do
          pipeline = Pipeline.new do |ppln|
            ppln.define_operation('ptiff_conversion')
            ppln.define_operation('exif_restoration')
            ppln.define_operation('exif_redaction',
                                  redact_tags: %w[CreatorTool Software])
          end

          pipeline.apply_to versioned_file
        end

        let :expected_values do
          {
            'JFIFVersion' => 1.01,
            'EncodingProcess' => 'Baseline DCT, Huffman coding',
            'ColorComponents' => 3,
            'Aperture' => 8.0,
            'DateTimeCreated' => Time.new(2017, 11, 30, 11, 33, 15),
            'DigitalCreationDateTime' => Time.new(2017, 11, 30, 11, 33, 15),
            'ScaleFactor35efl' => 2.0,
            'ShutterSpeed' => Rational(1, 100),
            'CircleOfConfusion' => '0.015 mm',
            'FOV' => '22.6 deg',
            'FocalLength35efl' => '45.0 mm (35 mm equivalent: 90.0 mm)',
            'HyperfocalDistance' => '16.85 m',
            'LightValue' => 10.0
          }
        end

        after { FileUtils.rm_r exampledir1 if File.exist? exampledir1 }

        it { is_expected.to eq expected_values }
      end
    end

    describe '#versions' do
      subject { versioned_file.versions }

      context 'when no modifications or cloning have occurred' do
        it { is_expected.to contain_exactly versioned_file.original }
      end

      context 'when modifications or cloning have occurred' do
        before { versioned_file.clone }

        it { is_expected.to include a_timestamp_filename }
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength
