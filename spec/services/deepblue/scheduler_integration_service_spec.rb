# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::SchedulerIntegrationService do

  describe 'module debug verbose variables' do
    it { expect( described_class.scheduler_integration_service_debug_verbose ).to eq( false ) }
  end

  describe 'other module values' do
    it { expect( described_class.scheduler_heartbeat_email_targets ).to eq( [ 'fritx@umich.edu' ] ) }
    it { expect( described_class.scheduler_log_echo_to_rails_logger ).to eq true }
    it { expect( described_class.scheduler_start_job_default_delay ).to eq 5.minutes.to_i }
    it { expect( described_class.scheduler_active ).to eq false }
    it { expect( described_class.scheduler_job_file_path ).to eq Rails.application.root.join( 'data',
                                                                                              'scheduler',
                                                                                              'scheduler_jobs.yml' ) }

    it { expect( described_class.scheduler_autostart_servers ).to eq [ 'testing.deepblue.lib.umich.edu',
                                           'staging.deepblue.lib.umich.edu',
                                           'deepblue.lib.umich.edu' ] }

    it { expect( described_class.scheduler_autostart_emails ).to eq [ 'fritx@umich.edu' ] }

  end

end
