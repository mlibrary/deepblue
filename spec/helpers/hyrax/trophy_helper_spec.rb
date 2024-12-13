# frozen_string_literal: true
# Update: hyrax4

require 'rails_helper'

RSpec.describe Hyrax::TrophyHelper, type: :helper, skip: false do
  describe "#display_trophy_link" do
    let(:user) { factory_bot_create_user(:user) }
    let(:id) { '9999' }

    let(:text_attributes) { '[data-add-text="Highlight work on profile"][data-remove-text="Unhighlight work"]' }
    let(:url_attribute) { "[data-url=\"/works/#{id}/trophy\"]" }

    context "when there is no trophy" do
      it "has a link for highlighting" do
        out = helper.display_trophy_link(user, id) { |text| "foo #{text} bar" }
        node = Capybara::Node::Simple.new(out)
        expect(node).to have_selector("a.trophy-class.trophy-off#{text_attributes}#{url_attribute}")
        expect(node).to have_link 'foo Highlight work on profile bar', href: '#'
      end
    end

    context "when there is a trophy" do
      before do
        user.trophies.create(work_id: id)
      end

      it "has a link for highlighting" do
        out = helper.display_trophy_link(user, id) { |text| "foo #{text} bar" }
        node = Capybara::Node::Simple.new(out)
        expect(node).to have_selector("a.trophy-class.trophy-on#{text_attributes}#{url_attribute}")
        expect(node).to have_link 'foo Unhighlight work bar', href: '#'
      end

      it "allows removerow to be passed" do
        out = helper.display_trophy_link(user, id, data: { removerow: true }) { |text| "foo #{text} bar" }
        node = Capybara::Node::Simple.new(out)
        expect(node).to have_selector("a.trophy-class.trophy-on[data-removerow=\"true\"]#{text_attributes}#{url_attribute}")
      end
    end
  end
end
