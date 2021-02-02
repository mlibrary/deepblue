require 'rails_helper'

RSpec.describe "hyrax/dashboard/show_scheduler_dashboard.html.erb", type: :view, skip: true do

  let(:user)       { build(:admin) }
  let(:ability)    { instance_double("Ability") }
  let(:controller) { SchedulerDashboardController.new }
  let(:presenter)  { SchedulerDashboardPresenter.new( controller: controller, current_ability: ability ) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
  end

  it "includes recent activities and notifications" do
    render
    expect(rendered).to have_content t( 'simple_form.scheduler_dashboard.labels.edit_schedule_textarea' )
    expect(rendered).to have_content t( 'hyrax.scheduler.edit_schedule_header' )
  end

end
