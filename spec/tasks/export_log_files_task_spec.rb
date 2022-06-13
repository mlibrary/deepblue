require 'rails_helper'

require_relative '../../app/services/deepblue/find_and_fix_service'
require_relative '../../app/services/deepblue/message_handler'
require_relative '../../lib/tasks/export_log_files_task'

RSpec.describe ::Deepblue::ExportLogFilesTask do

  describe 'run calls the service' do
    let(:id) { 'workid' }
    let(:options) { { option: 'value' } }
    let(:task) { described_class.new( options: options ) }

    it 'with expected args' do
      expect(::Deepblue::ExportFilesHelper).to receive(:export_log_files) do |args|
        expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
        expect(args[:msg_handler].to_console).to eq true
        expect(args[:task]).to eq true
        expect(args[:debug_verbose]).to eq false
      end
      task.run
    end

  end

end
