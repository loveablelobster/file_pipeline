# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'file_pipeline'
  s.version = '0.1.0'
  s.summary = 'Nondestructive file processing with a defined batch'
  s.author = 'Martin Stein'
  s.files = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.rdoc']
  s.homepage = 'https://github.com/loveablelobster/file_pipeline'
  s.license = 'MIT'
  s.email = 'loveablelobster@fastmail.fm'
  s.description = 'The file_pipeline gem provides a framework for'\
                  ' nondestructive application of file operation batches to'\
                  ' files.'
  s.required_ruby_version = '>= 2.7'
  s.add_runtime_dependency('multi_exiftool', '~> 0.14.0')
  s.add_runtime_dependency('ruby-vips', '~> 2.0.17')
end
