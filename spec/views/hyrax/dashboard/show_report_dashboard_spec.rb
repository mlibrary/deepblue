require 'rails_helper'

RSpec.describe "hyrax/dashboard/show_report_dashboard.html.erb", type: :view, skip: false do
  let(:user)       { build(:admin) }
  let(:ability)    { instance_double("Ability") }
  let(:presenter)  { ReportDashboardPresenter.new( controller: controller, current_ability: ability ) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
  end

  it "includes recent activities and notifications" do
    render
    expect(rendered).to have_content t( 'simple_form.report_dashboard.labels.edit_report_textarea' )
    expect(rendered).to have_content t( 'simple_form.report_dashboard.labels.report_file_path' )
  end

end
