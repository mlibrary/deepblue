# frozen_string_literal: true

require 'rails_helper'

require_relative '../../app/tasks/deepblue/report_task'

RSpec.describe ReportTaskJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variable' do
    it { expect( described_class.report_task_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.report_task_allowed_path_extensions ).to eq [ '.yml', '.yaml' ] }
    it { expect( described_class.report_task_allowed_path_prefixes ).to eq [ "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}",
                                                             './lib/reports/',
                                                             './data/reports/',
                                                             "#{::Deepblue::GlobusIntegrationService.globus_upload_dir}" ] +
                                                                             Rails.configuration.shared_drive_mounts }
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared ReportTaskJob' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.report_task_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.report_task_job_debug_verbose = debug_verbose
      end
      context do

        let(:report_task) { class_double(::Deepblue::ReportTask ).as_stubbed_const(:transfer_nested_constants => true) }
        let(:task)        { instance_double(::Deepblue::ReportTask ) }
        let(:reporter)    { "reporter@umich.edu" }
        let(:msg_handler) { ::Deepblue::MessageHandler.new( debug_verbose: dbg_verbose,
                                                            to_console: false,
                                                            verbose: false ) }
        let(:options)     { {} }
        let(:allowed_path_extensions) { [ '.yml', '.yaml' ] }
        let(:allowed_path_prefixes)   { [ "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}",
                                          './lib/reports/',
                                          './data/reports/',
                                          "#{::Deepblue::GlobusIntegrationService.globus_upload_dir}" ] +
                                          Rails.configuration.shared_drive_mounts }

        context 'with valid arguments and two paths' do
          let(:path1) { '/some/path/to/report1' }
          let(:report_file_path) { path1 }
          let(:job)              { described_class.send( :job_or_instantiate,
                                                         reporter: reporter,
                                                         report_file_path: report_file_path,
                                                         **options ) }

          before do
            expect( job ).to receive( :init_report_file_path ).with( report_file_path ).and_call_original
            expect( job ).to receive( :validate_report_file_path ).with( no_args ).and_return true
            expect( job ).to receive( :email_results ).with( no_args )
            expect( job ).to_not receive( :email_failure ).with( any_args )
            allow( job ).to receive(:msg_handler).and_return msg_handler
            expect( report_task ).to receive(:new ).with( allowed_path_extensions: allowed_path_extensions,
                                                          allowed_path_prefixes: allowed_path_prefixes,
                                                          reporter: reporter,
                                                          report_definitions_file: path1,
                                                          msg_handler: msg_handler,
                                                          options: options ).and_return task
            expect( task ).to receive(:run ).with( no_args )
          end

          it 'it performs the job' do
            expect( job.hostname ).to eq Rails.configuration.hostname
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
            expect( job.reporter ).to eq reporter
            expect( job.report_file_path ).to eq report_file_path
          end

        end

        describe '.hostname' do
          let(:job)       { described_class.send( :job_or_instantiate,
                                                  reporter: reporter,
                                                  report_file_path: '',
                                                  **options ) }
          it 'returns the application hostname' do
            expect( job.hostname ).to eq Rails.configuration.hostname
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end
      end
    end
    it_behaves_like 'shared ReportTaskJob', false
    it_behaves_like 'shared ReportTaskJob', true
  end

end
