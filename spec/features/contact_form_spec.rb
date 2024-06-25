# frozen_string_literal: true
# Skip: hyrax4
require 'rails_helper'

RSpec.describe "Sending an email via the contact form", type: :feature, js: true, clean_repo: true, skip: true || ENV['CIRCLECI'].present? do

  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "sends mail" do
    visit '/'
    click_link "Contact"
    expect(page).to have_content "Contact Form"
    fill_in "Your Name", with: "Test McPherson"
    fill_in "Your Email", with: "archivist1@example.com"
    fill_in "Message", with: "I am contacting you regarding ScholarSphere."
    fill_in "Subject", with: "My Subject is Cool"
    select "Depositing content", from: "Issue Type"
    click_button "Send"
    expect(page).to have_content "Thank you for your message!"
  end

end
