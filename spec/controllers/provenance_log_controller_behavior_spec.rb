require 'rails_helper'

class ProvLogControllerBehaviorMock
  include ProvenanceLogControllerBehavior

  attr_accessor :id

  def initialize(id:)
    @id
  end

end

RSpec.describe ProvenanceLogControllerBehavior do

  let(:debug_verbose) { false }

  it { expect( described_class.provenance_log_controller_behavior_debug_verbose ).to eq debug_verbose }

  describe '#provenance_log_entries?' do
    let(:id) { '123456789' }
    let(:path) { ::Deepblue::ProvenancePath.path_for_reference( id ) }
    let(:mock) { ProvLogControllerBehaviorMock.new(id: id) }
    before do
      expect( File ).to receive(:exist?).with( path ).and_return true
    end
    it { expect(mock.provenance_log_entries?(id: id)).to eq true }
  end

end
