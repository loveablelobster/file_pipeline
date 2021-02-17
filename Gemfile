# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :development do
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
end

group :test, :development do
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'
end

group :test do
  gem 'rspec'
end

gemspec
