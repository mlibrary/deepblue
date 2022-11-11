require 'rails_helper'

class WorkflowEventBehaviorCCMock
  include ::Deepblue::WorkflowEventBehavior

  attr_accessor :date_modified, :id

  def initialize(id)
    @id = id
  end

  def email_event_create_rds( current_user:, event_note:, was_draft: ); end
  def email_event_create_user( current_user:, event_note:, was_draft: ); end
  def email_event_destroy_rds( current_user:, event_note: ); end
  def email_event_destroy_user( current_user:, event_note:, was_draft: ); end
  def email_event_publish_rds( current_user:, event_note:, message: ); end
  def email_event_publish_user( current_user:, event_note:, message: ); end
  def email_event_unpublish_rds( current_user:, event_note: ); end
  def globus_clean_download_then_recopy(); end
  def provenance_create( current_user:, event_note: ); end
  def provenance_embargo( current_user:, event_note: ); end
  def provenance_destroy( current_user:, event_note: ); end
  def provenance_publish( current_user:, event_note:, message: ); end
  def provenance_unembargo( current_user:, event_note: ); end
  def provenance_unpublish( current_user:, event_note: ); end
  def save!; end

end

class WorkflowEventBehaviorCCMock2 < WorkflowEventBehaviorCCMock
  attr_accessor :date_published
  def doi_mint( current_user:, event_note: ); end
end

class WorkflowEventBehaviorCCMock3 < WorkflowEventBehaviorCCMock
  def doi_mint( current_user:, event_note: ); end
end

RSpec.describe ::Deepblue::WorkflowEventBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.workflow_event_behavior_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.workflow_create_debug_verbose ).to eq false }
    it { expect( described_class.workflow_update_after_debug_verbose ).to eq false }
  end

  describe 'event method' do
    let(:event_note)       { 'A note for the event.' }
    let(:user)             { 'A User' }

    describe '.workflow_create' do
      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to receive(:provenance_create).with( current_user: user, event_note: event_note)
          expect(curation_concern).to receive(:email_event_create_rds).with(current_user: user,
                                                                            event_note: event_note,
                                                                            was_draft: false)
          expect(curation_concern).to receive(:email_event_create_user).with(current_user: user,
                                                                            event_note: event_note,
                                                                            was_draft: false)
        end

        context 'is not draft' do
          before do
            expect(::Deepblue::DraftAdminSetService).to receive(:has_draft_admin_set?).with(curation_concern).and_return false
            expect(::Deepblue::TicketHelper).to receive(:new_ticket).with(cc_id: id,
                                                                     debug_verbose: false,
                                                                     current_user: user)
          end
          it { curation_concern.workflow_create(current_user: user, event_note: event_note ) }
        end

        context 'is draft' do
          before do
            expect(::Deepblue::DraftAdminSetService).to receive(:has_draft_admin_set?).with(curation_concern).and_return true
            expect(::Deepblue::TicketHelper).to_not receive(:new_ticket)
          end
          it { curation_concern.workflow_create(current_user: user, event_note: event_note ) }
        end

      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_create)
          expect(curation_concern).to_not receive(:email_event_create_rds)
          expect(curation_concern).to_not receive(:email_event_create_user)
          expect(::Deepblue::DraftAdminSetService).to_not receive(:has_draft_admin_set?)
          expect(::Deepblue::TicketHelper).to_not receive(:new_ticket)
        end
        it { curation_concern.workflow_create(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_destroy' do
      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to receive(:provenance_destroy).with( current_user: user, event_note: event_note )
          expect(curation_concern).to receive(:email_event_destroy_rds).with(current_user: user,
                                                                             event_note: event_note)
          expect(::Deepblue::DraftAdminSetService).to receive(:has_draft_admin_set?).with(curation_concern).and_return false
          expect(curation_concern).to receive(:email_event_destroy_user).with(current_user: user,
                                                                              event_note: event_note,
                                                                              was_draft: false)
        end
        it { curation_concern.workflow_destroy(current_user: user, event_note: event_note ) }
      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_destroy)
          expect(curation_concern).to_not receive(:email_event_destroy_rds)
          expect(::Deepblue::DraftAdminSetService).to_not receive(:has_draft_admin_set?)
          expect(curation_concern).to_not receive(:email_event_destroy_user)
        end
        it { curation_concern.workflow_destroy(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_embargo' do
      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
           expect(curation_concern).to receive(:provenance_embargo).with(current_user: user, event_note: event_note)
        end

        it { curation_concern.workflow_embargo(current_user: user, event_note: event_note ) }
      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_embargo)
        end
        it { curation_concern.workflow_embargo(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_publish' do
      let(:message) { 'Publish message.' }

      context 'with id' do
        let(:id) { 'an_id' }

        context 'respond_to? :date_published' do
          let(:curation_concern) { WorkflowEventBehaviorCCMock2.new(id) }
          before do
            expect(curation_concern).to receive(:provenance_publish).with(current_user: user,
                                                                          event_note: event_note,
                                                                          message: message)
            expect(curation_concern).to receive(:doi_mint).with(current_user: user, event_note: event_note)
            expect(curation_concern).to receive(:globus_clean_download_then_recopy).with(no_args)
            expect(curation_concern).to receive(:email_event_publish_rds).with(current_user: user,
                                                                               event_note: event_note,
                                                                               message: message)
            expect(curation_concern).to receive(:email_event_publish_user).with(current_user: user,
                                                                                event_note: event_note,
                                                                                message: message)
            expect(curation_concern).to receive(:date_published=).with(any_args)
            expect(curation_concern).to receive(:date_modified=).with(any_args)
            expect(curation_concern).to receive(:save!).with(any_args)
          end
          it { curation_concern.workflow_publish(current_user: user, event_note: event_note, message: message ) }
        end

        context 'does not respond_to? :date_published' do
          let(:curation_concern) { WorkflowEventBehaviorCCMock3.new(id) }
          before do
            expect(curation_concern).to receive(:provenance_publish).with(current_user: user,
                                                                          event_note: event_note,
                                                                          message: message)
            expect(curation_concern).to receive(:doi_mint).with(current_user: user, event_note: event_note)
            expect(curation_concern).to receive(:globus_clean_download_then_recopy).with(no_args)
            expect(curation_concern).to receive(:email_event_publish_rds).with(current_user: user,
                                                                               event_note: event_note,
                                                                               message: message)
            expect(curation_concern).to receive(:email_event_publish_user).with(current_user: user,
                                                                                event_note: event_note,
                                                                                message: message)
            expect(curation_concern).to_not receive(:date_modified=)
            expect(curation_concern).to_not receive(:save!)
          end
          it { curation_concern.workflow_publish(current_user: user, event_note: event_note, message: message ) }
        end

      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_publish)
          expect(curation_concern).to_not receive(:email_event_create_rds)
          expect(curation_concern).to_not receive(:email_event_create_user)
          expect(::Deepblue::DraftAdminSetService).to_not receive(:has_draft_admin_set?)
          expect(::Deepblue::TicketHelper).to_not receive(:new_ticket)
        end
        it { curation_concern.workflow_publish(current_user: user, event_note: event_note, message: message ) }
      end

    end

    describe '.workflow_publish_doi_mint' do
      let(:message) { 'Publish message.' }

      before do
        allow(::Deepblue::DoiMintingService).to receive(:doi_mint_on_publication_event).and_return true
      end

      context 'with id' do
        let(:id) { 'an_id' }

        context 'respond_to? :doi_mint' do
          let(:curation_concern) { WorkflowEventBehaviorCCMock3.new(id) }
          before do
            expect(curation_concern).to receive(:doi_mint).with(current_user: user, event_note: event_note)
          end
          it { curation_concern.workflow_publish_doi_mint(current_user: user, event_note: event_note ) }
        end

        context 'does not respond_to? :doi_mint' do
          let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
          it { curation_concern.workflow_publish_doi_mint(current_user: user, event_note: event_note ) }
        end

      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock3.new(id) }
        before do
          expect(curation_concern).to_not receive(:doi_mint)
        end
        it { curation_concern.workflow_publish_doi_mint(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_unembargo' do
      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to receive(:provenance_unembargo).with(current_user: user, event_note: event_note)
        end

        it { curation_concern.workflow_unembargo(current_user: user, event_note: event_note ) }
      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_embargo)
        end
        it { curation_concern.workflow_unembargo(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_unpublish' do
      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to receive(:provenance_unpublish).with(current_user: user, event_note: event_note)
          expect(curation_concern).to receive(:email_event_unpublish_rds).with(current_user: user, event_note: event_note)
        end

        it { curation_concern.workflow_unpublish(current_user: user, event_note: event_note ) }
      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:provenance_unpublish)
          expect(curation_concern).to_not receive(:email_event_unpublish_rds)
        end
        it { curation_concern.workflow_unpublish(current_user: user, event_note: event_note ) }
      end

    end

    describe '.workflow_update_after' do

      context 'with id' do
        let(:id) { 'an_id' }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }

        context 'submit for review' do
          before do
            expect(curation_concern).to receive(:email_event_create_rds).with(current_user: user,
                                                                              event_note: event_note,
                                                                              was_draft: true)
            expect(curation_concern).to receive(:email_event_create_user).with(current_user: user,
                                                                               event_note: event_note,
                                                                               was_draft: true)
            expect(::Deepblue::TicketHelper).to receive(:new_ticket).with(cc_id: id,
                                                                     debug_verbose: false,
                                                                     current_user: user)
          end
          it { curation_concern.workflow_update_after(current_user: user,
                                                      event_note: event_note,
                                                      submit_for_review: true ) }
        end

        context 'not submit for review' do
          before do
            expect(curation_concern).to_not receive(:email_event_create_rds)
            expect(curation_concern).to_not receive(:email_event_create_user)
            expect(::Deepblue::TicketHelper).to_not receive(:new_ticket)
          end
          it { curation_concern.workflow_update_after(current_user: user,
                                                      event_note: event_note,
                                                      submit_for_review: false ) }
        end

      end

      context 'with nil id' do
        let(:id) { nil }
        let(:curation_concern) { WorkflowEventBehaviorCCMock.new(id) }
        before do
          expect(curation_concern).to_not receive(:email_event_create_rds)
          expect(curation_concern).to_not receive(:email_event_create_user)
          expect(::Deepblue::TicketHelper).to_not receive(:new_ticket)
        end
        it { curation_concern.workflow_update_after(current_user: user, event_note: event_note ) }
      end

    end

  end

end
