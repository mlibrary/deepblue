# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::LoggingIntializationService do

  # let(:debug_verbose) { false }

  it { expect( described_class.suppress_active_support_logging ).to eq true }
  it { expect( described_class.suppress_active_support_logging_verbose ).to eq true }
  it { expect( described_class.suppress_blacklight_logging ).to eq true }
  it { expect( described_class.active_support_list_ids ).to eq false }
  it { expect( described_class.active_support_suppressed_ids ).to eq [ "ldp.active_fedora",
                                                                     "logger.active_fedora",
                                                                     # "render_collection.action_view",
                                                                     # "render_partial.action_view",
                                                                     # "render_template.action_view",
                                                                     "sql.active_record",
                                                                     "transmit_subscription_confirmation.action_cable",
                                                                     "transmit_subscription_rejection.action_cable" ] }

end
