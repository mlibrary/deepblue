require 'rails_helper'

require_relative '../../app/services/deepblue/find_and_fix_service'
require_relative '../../app/services/deepblue/message_handler'
require_relative '../../lib/tasks/work_find_and_fix_task'

RSpec.describe ::Deepblue::WorkFindAndFixTask do

  describe 'run calls the service' do
    let(:id) { 'workid' }
    let(:options) { { option: 'value' } }
    let(:task) { described_class.new( id: id, options: options ) }

    it 'with expected args' do
      expect(::Deepblue::FindAndFixService).to receive(:work_find_and_fix) do |args|
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
