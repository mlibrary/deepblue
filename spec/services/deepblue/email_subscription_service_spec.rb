# frozen_string_literal: true

require 'rails_helper'

# require_relative '../../../app/helpers/deepblue/email_helper'

RSpec.describe ::Deepblue::EmailSubscriptionService, clean_repo: true do

  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:user3) { build(:user) }
  let(:subscription_id1) { 'ExpeditionReports' }
  let(:subscription_id2) { 'ForYourEyesOnly' }
  let(:subscription_unknown) { 'PeopleOfTheLandThatTimeForgot' }
  let(:sub_parms1) { Array( 'lost') }
  # need to find out how to get the actual class to double here:
  # let(:email_helper) { class_double("Deepblue::EmailHelper") }
  let(:email_helper) { class_double( Deepblue::EmailHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  before do
    EmailSubscription.new( subscription_name: subscription_id1,
                           user_id: user1.id,
                           email: user1.email,
                           subscription_parameters: sub_parms1 ).save
    EmailSubscription.new( subscription_name: subscription_id2,
                           user_id: user1.id,
                           email: user1.email ).save
    EmailSubscription.new( subscription_name: subscription_id2,
                           user_id: user2.id,
                           email: user2.email ).save
    expect( EmailSubscription.where( subscription_name: subscription_id1 ).size ).to be == 1
    expect( EmailSubscription.where( subscription_name: subscription_id2 ).size ).to be == 2
  end

  describe 'constants' do
    it "resolves them" do
      expect( ::Deepblue::EmailSubscriptionService.email_subscription_service_debug_verbose ).to eq( false )
    end
  end

  describe ".merge_targets_and_subscribers" do
    let(:target1) { "target1@some.com" }
    let(:targets) { [target1] }

    context 'blank subscription id' do
      subject { described_class.merge_targets_and_subscribers( targets: targets,
                                                               subscription_service_id: '' ) }

      it 'it returns the targets' do
        expect(subject).to eq targets
      end
    end

    context 'it returns both targets and subscribers' do
      subject { described_class.merge_targets_and_subscribers( targets: targets,
                                                               subscription_service_id: subscription_id1 ) }

      it 'finds the subscribers and returns subscription parameter' do
        expect(subject).to eq targets + [ user1.email ]
      end
    end

    context 'it removes duplicates' do
      subject { described_class.merge_targets_and_subscribers( targets: [ user1.email ],
                                                               subscription_service_id: subscription_id1 ) }

      it 'finds the subscribers and returns subscription parameter' do
        expect(subject).to eq [ user1.email ]
      end
    end

  end

  describe ".subscribers_for" do

    context 'known subscription service id' do
      subject { described_class.subscribers_for( subscription_service_id: subscription_id1 ) }

      it 'finds some subscribers' do
        expect(subject).to eq [ user1.email ]
      end
    end

    context 'known subscription service id and return parameters' do
      subject { described_class.subscribers_for( subscription_service_id: subscription_id1,
                                                 include_parameters: true ) }

      it 'finds the subscribers and returns subscription parameter' do
        expect(subject).to eq [ [user1.email, sub_parms1] ]
      end
    end

    context 'known subscription service id' do
      subject { described_class.subscribers_for( subscription_service_id: subscription_unknown ) }

      it 'does not find any subscribers' do
        expect(subject).to eq []
      end
    end

  end

  describe ".subscription_send_email" do

    context 'known subscription service id' do
      let(:content_type) { "html" }
      let(:hostname) { "mail:host" }
      let(:email_subject) { "The Subject of the Email" }
      let(:body) { "Dear subscriber,\nTake notice.\nYour Humble Servant" }
      let(:event) { "AnEvent" }
      let(:email_sent) { true }
      let(:class_name) { ::Deepblue::EmailSubscriptionService.class.name }
      subject { described_class.subscription_send_email( email_target: user2.email,
                                                         content_type: content_type,
                                                         hostname: hostname,
                                                         subject: email_subject,
                                                         body: body,
                                                         event: event,
                                                         event_note: '',
                                                         id: 'NA',
                                                         subscription_service_id: subscription_id2 ) }

      before do
        # expect( email_helper ).to receive( :send_email ).with( any_args )
        expect( email_helper ).to receive( :send_email ).with( to: user2.email,
                                                               subject: email_subject,
                                                               body: body,
                                                               content_type: content_type ).and_return email_sent
        expect( email_helper ).to receive( :log ).with( class_name: class_name,
                                                        current_user: nil,
                                                        event: event,
                                                        event_note: '',
                                                        id: 'NA',
                                                        to: user2.email,
                                                        from: user2.email,
                                                        subject: email_subject,
                                                        body: body,
                                                        email_sent: email_sent )
      end

      it 'sends the email' do
        expect(subject).to eq nil
      end
    end

  end

end
