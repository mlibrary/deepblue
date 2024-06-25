# frozen_string_literal: true
# Reviewed: hyrax4
FactoryBot.define do
  factory :hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    title { ['My Admin Set'] }
  end
end
