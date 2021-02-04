require 'rails_helper'

RSpec.describe "hyrax/dashboard/show_ingest_dashboard.html.erb", type: :view, skip: false do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }

  let(:user)       { build(:admin) }
  let(:ability)    { instance_double("Ability") }
  let(:presenter)  { IngestDashboardPresenter.new( controller: controller, current_ability: ability ) }

  before do
    view.controller = IngestDashboardController.new
    view.controller.action_name = 'show'
    allow(view).to receive(:main_app).and_return main_app
    presenter.controller = view.controller
    allow(view.controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
    assign(:view_presenter, presenter)
    render
  end

  it "includes recent activities and notifications" do
    expect(rendered).to have_content t( 'simple_form.ingest_dashboard.labels.ingest_file_paths_textarea' )
    # expect(rendered).to have_content t( 'simple_form.actions.ingest.run_append_ingests_job' )
    # expect(rendered).to have_content t( 'simple_form.actions.ingest.run_populate_ingests_job' )
  end

end
