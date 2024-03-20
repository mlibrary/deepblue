# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::RegisterDoiJob, type: :job do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( ::Deepblue::DoiMintingService.register_doi_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared ::Deepblue::RegisterDoiJob' do |dbg_verbose|
      subject { described_class }
      before do
        ::Deepblue::DoiMintingService.register_doi_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        ::Deepblue::DoiMintingService.register_doi_job_debug_verbose = debug_verbose
      end
      context do

        # let(:model_class) do
        #   Class.new(DataSet) do
        #     include Deepblue::DoiBehavior
        #   end
        # end
        let(:work) { create(:data_set, title: ['Moomin']) }

        before do
          # Stubbed here for ActiveJob deserialization
          stub_const("WorkWithDOI", DataSet)
        end

        describe '.perform_later' do
          before { ActiveJob::Base.queue_adapter = :test }

          it 'enqueues the job' do
            expect { described_class.perform_later(work) }
              .to enqueue_job(described_class)
                    .with(work)
                    .on_queue(:doi_minting)
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end

        describe '.perform' do
          let(:registrar_class) do
            Class.new(Hyrax::Identifier::Registrar) do
              def initialize(*); end

              def register!(*)
                Struct.new(:identifier).new('10.1234/moomin/123/abc')
              end
            end
          end
          let(:doi) { '10.1234/moomin/123/abc' }
          let(:registrar) { :moomin }
          let(:registrar_opts) { { builder: 'CustomBuilderClass', connection: 'CustomConnectionClass' } }

          before do
            # allow(Hyrax.config).to receive(:identifier_registrars).and_return(abstract: Hyrax::Identifier::Registrar,
            #                                                                   moomin: registrar_class)
            expect(Hyrax.config).to_not receive(:identifier_registrars)
            allow(registrar_class).to receive(:new).and_call_original
            # expect(::Deepblue::DoiMintingService).to receive(:registrar_mint_doi).with( curation_concern: work,
            #                                                   current_user: nil,
            #                                                   debug_verbose: dbg_verbose,
            #                                                   registrar: nil,
            #                                                   registrar_opts: registrar_opts )
            expect(::Deepblue::DoiMintingService).to receive(:registrar_mint_doi) do |args|
              expect(args[:curation_concern]).to eq work
              expect(args[:current_user]).to eq nil
              expect(args[:debug_verbose]).to eq dbg_verbose
              # expect(args[:msg_handler]).to eq msg_handler
              expect(args[:registrar]).to eq nil
              expect(args[:registrar_opts]).to eq registrar_opts
            end
          end

          it 'calls the registrar' do
            # expect { described_class.perform_now(work, registrar: registrar.to_s, registrar_opts: registrar_opts) }
            #   .to change { work.doi }
            #         .to eq doi
            #expect(registrar_class).to have_received(:new).with(registrar_opts)
            described_class.perform_now( id: work.id, registrar: nil, registrar_opts: registrar_opts)
          end
        end
      end
    end
    it_behaves_like 'shared ::Deepblue::RegisterDoiJob', false
    it_behaves_like 'shared ::Deepblue::RegisterDoiJob', true
  end

end
