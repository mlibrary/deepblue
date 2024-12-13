require 'rails_helper'

class MockDeepblueDoiControllerBehavior

  include Deepblue::DoiControllerBehavior

  attr_accessor :curation_concern, :current_user, :current_ability

end

RSpec.describe Deepblue::DoiControllerBehavior, :clean_repo, clean: true do

  let(:debug_verbose) { false }

  let(:current_user_email) { "current_user@test.com" }
  let(:depositor_email) { "depositor@test.com" }
  # let(:current_user) { factory_bot_create_user(:user, id: 1, email: current_user_email) }
  # let(:depositor) { factory_bot_create_user(:user, id: 2, email: depositor_email) }
  let(:current_user) { factory_bot_create_user(:user, email: current_user_email) }
  let(:depositor) { factory_bot_create_user(:user, email: depositor_email) }
  let(:ability) { Ability.new(current_user) }

  describe 'module debug verbose variables' do
    it { expect( described_class.doi_controller_behavior_debug_verbose ).to eq( debug_verbose ) }
  end

  subject { MockDeepblueDoiControllerBehavior.new }

  it { expect( subject.doi_minting_enabled? ).to eq ::Deepblue::DoiBehavior.doi_minting_enabled }

  describe '.doi_mint' do

    RSpec.shared_examples 'it calls doi_mint' do |debug_verbose_count,doi_msg,mints_doi|
      let(:dbg_verbose) { debug_verbose_count > 0 }

      before do
        if 0 < debug_verbose_count
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
      end

      it 'it calls doi_mint' do
        allow(ability).to receive(:admin?).and_return false
        allow(subject).to receive(:curation_concern).and_return data_set
        allow(subject).to receive(:current_user).and_return current_user
        allow(subject).to receive(:current_ability).and_return ability
        expect(data_set).to receive(:doi_mint).with(any_args).and_return true if mints_doi
        described_class.doi_controller_behavior_debug_verbose = dbg_verbose
        expect(subject.doi_mint).to eq doi_msg
        described_class.doi_controller_behavior_debug_verbose = debug_verbose
      end

    end

    context 'doi pending' do
      let(:data_set) do
        work = create(:data_set_with_one_file, depositor: depositor_email, doi: ::Deepblue::DoiBehavior.doi_pending_init )
        work.depositor = depositor_email
        work
      end
      doi_msg = I18n.t( 'data_set.doi_is_being_minted' )
      mints_doi = false
      context 'normal' do
        it_behaves_like 'it calls doi_mint', 0, doi_msg, mints_doi
      end
      context 'debug verbose' do
        it_behaves_like 'it calls doi_mint', 1, doi_msg, mints_doi
      end
    end

    context 'doi already exists' do
      let(:data_set) { create(:data_set_with_one_file, depositor: depositor_email, doi: 'fake_doi') }
      let(:data_set) do
        work = create(:data_set_with_one_file, depositor: depositor_email, doi: 'fake_doi')
        work.depositor = depositor_email
        work
      end
      doi_msg = I18n.t( 'data_set.doi_already_exists' )
      mints_doi = false
      context 'normal' do
        it_behaves_like 'it calls doi_mint', 0, doi_msg, mints_doi
      end
      context 'debug verbose' do
        it_behaves_like 'it calls doi_mint', 1, doi_msg, mints_doi
      end
    end

    context 'must have files' do
      let(:data_set) do
        work = create(:data_set, depositor: depositor_email, doi: nil)
        work.depositor = depositor_email
        work
      end
      doi_msg = I18n.t( 'data_set.doi_requires_work_with_files' )
      mints_doi = false
      context 'normal' do
        it_behaves_like 'it calls doi_mint', 0, doi_msg, mints_doi
      end
      context 'debug verbose' do
        it_behaves_like 'it calls doi_mint', 1, doi_msg, mints_doi
      end
    end

    context 'must be depositor' do
      let(:data_set) do
        work = create(:data_set_with_one_file, depositor: depositor_email, doi: nil)
        work.depositor = depositor_email
        work
      end
      doi_msg = I18n.t( 'data_set.doi_user_without_access' )
      mints_doi = false
      context 'normal' do
        it_behaves_like 'it calls doi_mint', 0, doi_msg, mints_doi
      end
      context 'debug verbose' do
        it_behaves_like 'it calls doi_mint', 1, doi_msg, mints_doi
      end
    end

    context 'and calls mint doi' do
      let(:data_set) do
        work = create(:data_set_with_one_file, depositor: current_user_email, doi: nil)
        work.depositor = current_user_email
        work
      end
      doi_msg = I18n.t( 'data_set.doi_minting_started' )
      mints_doi = true
      context 'normal' do
        it_behaves_like 'it calls doi_mint', 0, doi_msg, mints_doi
      end
      context 'debug verbose' do
        it_behaves_like 'it calls doi_mint', 1, doi_msg, mints_doi
      end
    end

  end

end
