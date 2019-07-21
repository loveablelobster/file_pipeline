# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :a_collection_excluding, :include
RSpec::Matchers.define_negated_matcher :not_eq, :eq
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec::Matchers.define :be_uuid do
  match do |actual|
    /^[0-9a-z]{8}-([0-9a-z]{4}-){3}[0-9a-z]{12}$/.match? actual
  end
end

RSpec::Matchers.define :a_randomized_filename do
  match do |actual|
    /[0-9a-z]{8}-([0-9a-z]{4}-){3}[0-9a-z]{12}\.\w+$/.match? actual
  end
end

RSpec::Matchers.define :be_timestamp do
  match do |actual|
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{9}$/.match? actual
  end
end

RSpec::Matchers.define :a_timestamp_filename do
  match do |actual|
    /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{9}\.\w+$/.match? actual
  end
end

RSpec::Matchers.alias_matcher :be_a_timestamp_filename, :a_timestamp_filename
RSpec::Matchers.alias_matcher :an_array_excluding, :a_collection_excluding
