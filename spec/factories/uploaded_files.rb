# frozen_string_literal: true
# Update: hyrax4
FactoryBot.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
    file { File.open('spec/fixtures/image.jp2') }
  end
end
