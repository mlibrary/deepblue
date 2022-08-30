require 'rails_helper'

class ProvenanceBehaviorCCMock
  include ::Deepblue::ProvenanceBehavior

  # attr_accessor :date_modified, :id
  #
  # def initialize(id, attributes: {})
  #   @id = id
  #   @attributes = attributes.dup
  # end
  #
  # def [](key)
  #   @attributes[key]
  # end
  #
  # def []=(key, value)
  #   @attributes[key] = value
  # end
  #
  # def event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil ); end

end

RSpec.describe ::Deepblue::ProvenanceBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.provenance_behavior_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.provenance_log_update_after_debug_verbose ).to eq false }
    it { expect( described_class.provenance_update_debug_verbose ).to eq false }
  end

end
