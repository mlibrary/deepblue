FactoryBot.define do
  factory :anonymous_link do
    factory :show_anon_link do
      itemId { 'fs-id' }
      path { '/concerns/data_set/1234' }
    end

    factory :download_anon_link do
      itemId { 'fs-id' }
      path { '/downloads/1234' }
    end
  end
end
