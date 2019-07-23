# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'file_pipeline'
  s.version = '0.0.1'
  s.summary = 'Nondestructive file processing with a defined batch'
  s.author = 'Martin Stein'
  s.files = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  s.homepage = 'https://github.com/loveablelobster/file_pipeline'
  s.license = 'MIT'
  s.email = 'loveablelobster@fastmail.fm'
  s.description = File.read(File.join(__dir__, 'README.md'))
  s.add_runtime_dependency('multi_exiftool', '~> 0.11.0')
  s.add_runtime_dependency('ruby-vips', '~> 2.0.14')
end
