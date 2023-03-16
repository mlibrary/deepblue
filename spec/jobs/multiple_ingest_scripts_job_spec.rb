# frozen_string_literal: true

# keywords: create_job invoke_job perform_job class_double

require 'rails_helper'

RSpec.describe MultipleIngestScriptsJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.multiple_ingest_scripts_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.scripts_allowed_path_extensions ).to eq [ '.yml', '.yaml' ] }
    it { expect( described_class.scripts_allowed_path_prefixes ).to eq [ "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}",
                                                             './data/reports/',
                                                             "#{::Deepblue::GlobusIntegrationService.globus_upload_dir}" ] +
                                                                         Rails.configuration.shared_drive_mounts }
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared MultipleIngestScriptsJob' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.multiple_ingest_scripts_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.multiple_ingest_scripts_job_debug_verbose = debug_verbose
      end
      context do

        let(:subject_job) { class_double(IngestScriptJob).as_stubbed_const(:transfer_nested_constants => true) }
        let(:ingest_mode) { 'populate' }
        let(:ingester)    { "ingester@umich.edu" }
        let(:options)     { {} }

        context 'with valid arguments and two paths' do
          let(:path1)            { '/some/path/to/script1' }
          let(:path2)            { '/some/path/to/script2' }
          let(:paths_to_scripts) { [ path1, path2 ] }
          let(:job)              { described_class.send( :job_or_instantiate,
                                                         ingest_mode: ingest_mode,
                                                         ingester: ingester,
                                                         paths_to_scripts: paths_to_scripts,
                                                         **options ) }

          before do
            expect( job ).to receive( :init_paths_to_scripts ).with( paths_to_scripts ).and_call_original
            expect( job ).to receive( :validate_paths_to_scripts ).with( no_args ).and_return true
            expect( job ).to receive( :ingest_script_run ).with( path_to_script: path1 ).and_call_original
            expect( job ).to receive( :ingest_script_run ).with( path_to_script: path2 ).and_call_original
            expect( job ).to receive( :email_results ).with(no_args)
            expect( job ).to_not receive( :email_failure ).with( any_args )
            expect( subject_job ).to receive(:perform_now ).with( ingest_mode: ingest_mode,
                                                                  ingester: ingester,
                                                                  path_to_script: path1 )
            expect( subject_job ).to receive(:perform_now ).with( ingest_mode: ingest_mode,
                                                                  ingester: ingester,
                                                                  path_to_script: path2 )
          end

          it 'it performs the job' do
            expect( job.hostname ).to eq Rails.configuration.hostname
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
            expect( job.ingest_mode ).to eq ingest_mode
            expect( job.ingester ).to eq ingester
            expect( job.paths_to_scripts ).to eq paths_to_scripts
          end

        end

        describe '.hostname' do
          let(:job)       { described_class.send( :job_or_instantiate,
                                                  ingest_mode: ingest_mode,
                                                  ingester: ingester,
                                                  paths_to_scripts: [],
                                                  **options ) }
          it 'returns the application hostname' do
            expect( job.hostname ).to eq Rails.configuration.hostname
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end

        describe '.init_paths_to_scripts' do
          let(:path1) { '/some/path/to/script1' }
          let(:path2) { '/some/path/to/script2' }
          let(:job)   { described_class.send( :job_or_instantiate,
                                              ingest_mode: ingest_mode,
                                              ingester: ingester,
                                              paths_to_scripts: '',
                                              **options ) }

          context 'given an array of two paths, it sets paths_to_scripts to an array of with two paths' do
            it 'splits them properly' do
              job.init_paths_to_scripts( [path1,path2] )
              expect( job.paths_to_scripts ).to eq [path1,path2]
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end
          end

          context 'given a string with two paths, it sets paths_to_scripts to an array of with two paths' do
            it 'splits them properly' do
              job.init_paths_to_scripts( "#{path1}\n#{path2}\n" )
              expect( job.paths_to_scripts ).to eq [path1,path2]
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end
          end

          context 'given a string with two paths and empty lines, it sets paths_to_scripts to an array of with two paths' do
            it 'splits them properly' do
              job.init_paths_to_scripts( "  \n#{path1}\n#{path2}\n\n\n" )
              expect( job.paths_to_scripts ).to eq [path1,path2]
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end
          end

        end
      end
    end

    it_behaves_like 'shared MultipleIngestScriptsJob', false
    it_behaves_like 'shared MultipleIngestScriptsJob', true
  end

end
