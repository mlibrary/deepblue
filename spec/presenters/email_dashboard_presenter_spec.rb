require 'rails_helper'

class TestEmailPresenter < EmailDashboardPresenter
end

RSpec.describe EmailDashboardPresenter do

  let(:dummy_class) { double }
  let(:dummy2_class) { double }

  it "retrieves email template keys" do
    presenter = TestEmailPresenter.new controller: dummy_class, current_ability: dummy2_class
    dc = presenter.email_template_keys

    expect(dc).to eq(["N/A"])
  end

end
