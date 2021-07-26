FactoryBot.define do
  factory :single_use_link do
    factory :show_link do
      itemId { 'fs-id' }
      path { '/concerns/data_set/1234' }
    end

    factory :download_link do
      itemId { 'fs-id' }
      path { '/downloads/1234' }
    end
  end
end
