# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::ReportHelper, type: :helper do

  # let(:debug_verbose) { false }
  #
  # describe 'module variables' do
  #   it { expect( described_class.irus_log_echo_to_rails_logger ).to eq true }
  # end

  context '.expand_path_partials' do

    it { expect(described_class.expand_path_partials('')).to eq '' }

    # TODO:
    # path = path.gsub( /\%date\%/, "#{now.strftime('%Y%m%d')}" )
    # path = path.gsub( /\%time\%/, "#{now.strftime('%H%M%S')}" )
    # path = path.gsub( /\%timestamp\%/, "#{now.strftime('%Y%m%d%H%M%S')}" )

    it { expect(described_class.expand_path_partials('%hostname% in path')).to eq "#{Rails.configuration.hostname} in path" }

    # TODO: multiple expansions

  end

end
