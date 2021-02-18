# frozen_string_literal: true

RSpec.shared_context 'with tags', shared_context: :metadata do
  let(:tags) { FilePipeline::FileOperations::ExifManipulable.file_tags }

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
