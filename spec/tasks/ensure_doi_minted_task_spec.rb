require 'rails_helper'

require_relative '../../app/services/deepblue/message_handler'
require_relative '../../lib/tasks/ensure_doi_minted_task'

RSpec.describe ::Deepblue::EnsureDoiMintedTask do

  describe 'run calls the service' do
    let(:id) { 'workid' }
    let(:options) { { option: 'value' } }
    let(:task) { described_class.new( id: id, options: options ) }

    it 'with expected args' do
      expect(::Deepblue::DoiMintingService).to receive(:ensure_doi_minted) do |args|
        expect(args[:id]).to eq id
        expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
        expect(args[:msg_handler].to_console).to eq true
        expect(args[:task]).to eq true
        expect(args[:debug_verbose]).to eq false
      end
      task.run
    end

  end

end
