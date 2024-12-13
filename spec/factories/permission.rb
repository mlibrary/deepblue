# frozen_string_literal: true
# hyrax5 - copied

FactoryBot.define do
  factory :permission, class: "Hyrax::Permission" do
    agent { factory_bot_create_user(:user).user_key.to_s }
    mode  { :read }
  end
end
