# frozen_string_literal: true

RSpec.shared_context 'with variables', shared_context: :metadata do
  # Directories
  let :default_ops do
    File.expand_path 'lib/file_pipeline/file_operations/default_operations'
  end

  let(:test_ops) { File.expand_path 'spec/support/test_operations' }
  let(:target_dir) { File.expand_path 'spec/support/test_directory' }
  let(:exampledir1) { 'spec/support/example1_versions' }

  # Files
  let(:src_file1) { File.expand_path 'spec/support/example1.jpg' }
  let(:src_file2) { File.expand_path 'spec/support/example2.tif' }
  let(:src_file_ptiff) { 'spec/support/pyramid.tiff' }

  # Other
  let :non_writable_tags do
    include 'EncodingProcess' => 'Baseline DCT, Huffman coding',
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
  end
end
