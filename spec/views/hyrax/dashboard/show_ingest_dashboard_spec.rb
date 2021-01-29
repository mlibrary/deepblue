require 'rails_helper'

RSpec.describe "hyrax/dashboard/show_ingest_dashboard.html.erb", type: :view, skip: false do
  let(:user)       { build(:admin) }
  let(:ability)    { instance_double("Ability") }
  let(:presenter)  { IngestDashboardPresenter.new( controller: controller, current_ability: ability ) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    assign(:presenter, presenter)
  end

  it "includes recent activities and notifications" do
    render
    expect(rendered).to have_content t( 'simple_form.ingest_dashboard.labels.ingest_file_paths_textarea' )
    # expect(rendered).to have_content t( 'simple_form.actions.ingest.run_append_ingests_job' )
    # expect(rendered).to have_content t( 'simple_form.actions.ingest.run_populate_ingests_job' )
  end

end
