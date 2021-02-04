require 'rails_helper'

RSpec.describe "hyrax/dashboard/show_report_dashboard.html.erb", skip: false do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }

  let(:user)       { build(:admin) }
  let(:ability)    { instance_double("Ability") }
  let(:presenter)  { ReportDashboardPresenter.new( controller: controller, current_ability: ability ) }

  before do
    view.controller = ReportDashboardController.new
    view.controller.action_name = 'show'
    allow(view).to receive(:main_app).and_return main_app
    presenter.controller = view.controller
    allow(view.controller).to receive(:current_user).and_return(user)
    allow(view.controller).to receive(:report_file_path).and_return nil
    # NOTE: because the rspec test harness does not reliably pick up the connection between
    #       the presenter and the controller, hard code the presenter's return values
    allow(presenter).to receive(:controller).and_return controller
    allow(presenter).to receive(:current_ability).and_return ability
    allow(presenter).to receive(:report_allowed_path_prefixes).and_return [ '/prefix/', '/prefix2/']
    allow(presenter).to receive(:report_file_path).and_return '/report/file/path'
    allow(presenter).to receive(:run_button).and_return 'Run Button'
    allow(presenter).to receive(:edit_report_textarea).and_return ''
    assign(:presenter, presenter)
    assign(:view_presenter, presenter)
    render
  end

  it "includes recent activities and notifications" do
    expect(rendered).to have_content t( 'simple_form.report_dashboard.labels.edit_report_textarea' )
    expect(rendered).to have_content t( 'simple_form.report_dashboard.labels.report_file_path' )
  end

end
