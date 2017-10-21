# frozen_string_literal: true

FactoryBot.define do
  sequence(:filepath) do |n|
    "#{n}_#{Faker::File.file_name(nil, nil, 'txt')}"
  end
end
