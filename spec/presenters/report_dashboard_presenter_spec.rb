# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe ReportDashboardPresenter, skip: true do

  include Devise::Test::ControllerHelpers

  # let( :controller ) { instance_double( ReportDashboardController ) }
  # let( :controller2 ) { ReportDashboardController.new }
  let(:controller ) { instance_double( ReportDashboardController ) }
  let(:ability ) { double(Ability) }

  subject { described_class.new( controller: controller, current_ability: ability ) }

  before do
    allow(controller ).to receive( :edit_report_textarea ).and_return ''
    allow(controller ).to receive( :report_file_path ).and_return '/path'
  end

  it { expect(subject ).respond_to? :controller }
  it { expect(subject ).respond_to? :current_ability }

end
