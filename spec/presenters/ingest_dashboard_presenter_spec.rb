# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe IngestDashboardPresenter do
  subject { described_class.new(controller: double, current_ability: double) }

  it { expect( subject ).respond_to? :controller }
  it { expect( subject ).respond_to? :current_ability }

end
