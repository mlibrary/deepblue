# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/tasks/report_task'

RSpec.describe ReportTaskJob, skip: false do

  let(:report_task) { class_double(::Deepblue::ReportTask ).as_stubbed_const(:transfer_nested_constants => true) }
  let(:task)        { instance_double(::Deepblue::ReportTask ) }
  let(:reporter)    { "reporter@umich.edu" }
  let(:options)     { {} }
  let(:allowed_path_extensions) { [ '.yml', '.yaml' ] }
  let(:allowed_path_prefixes)   { [ '/deepbluedata-prep/',
                                    './data/reports/',
                                    '/deepbluedata-globus/uploads/' ] }

  describe 'module debug verbose variable' do
    it "they have the right values" do
      expect( described_class.report_task_job_debug_verbose ).to eq true
    end
  end

  describe 'module variables' do
    it "they have the right values" do
      expect( described_class.report_task_allowed_path_extensions ).to eq allowed_path_extensions
      expect( described_class.report_task_allowed_path_prefixes ).to eq allowed_path_prefixes
    end
  end

  context 'with valid arguments and two paths' do
    let(:path1) { '/some/path/to/report1' }
    let(:report_file_path) { path1 }
    let(:job)              { described_class.send( :job_or_instantiate,
                                                   reporter: reporter,
                                                   report_file_path: report_file_path,
                                                   **options ) }

    before do
      expect( described_class.report_task_job_debug_verbose ).to eq true
      expect( job ).to receive( :init_report_file_path ).with( report_file_path ).and_call_original
      expect( job ).to receive( :validate_report_file_path ).with( no_args ).and_return true
      expect( job ).to receive( :email_results ).with( no_args )
      expect( job ).to_not receive( :email_failure ).with( any_args )
      expect( report_task ).to receive(:new ).with( allowed_path_extensions: allowed_path_extensions,
                                                    allowed_path_prefixes: allowed_path_prefixes,
                                                    reporter: reporter,
                                                    report_definitions_file: path1,
                                                    options: options ).and_return task
      expect( task ).to receive(:run ).with( no_args )
    end

    it 'it performs the job' do
      expect( job.hostname ).to eq ::DeepBlueDocs::Application.config.hostname
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
      expect( job.hostname ).to eq ::DeepBlueDocs::Application.config.hostname
    end
  end

end
