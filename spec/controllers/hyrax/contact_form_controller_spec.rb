require 'rails_helper'

RSpec.describe Hyrax::ContactFormController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.contact_form_controller_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class.contact_form_send_email     ).to eq true }

    it { expect( described_class.contact_form_log_delivered  ).to eq true }
    it { expect( described_class.contact_form_log_spam       ).to eq true }
    it { expect( described_class.antispam_timeout_in_seconds ).to eq 8    }

    it { expect( described_class.akismet_enabled             ).to eq false }
    it { expect( described_class.akismet_env_slice_keys      ).to eq( %w{ HTTP_ACCEPT
                                                                          HTTP_ACCEPT_ENCODING
                                                                          REQUEST_METHOD
                                                                          SERVER_PROTOCOL
                                                                          SERVER_SOFTWARE
                                                                        } ) }
    it { expect( described_class.akismet_is_spam_only_if_blatant ).to eq true }
    it { expect( described_class.ngr_enabled                 ).to eq false }
    it { expect( described_class.ngr_just_human_test         ).to eq false }
  end

  let(:user) { factory_bot_create_user(:user) }
  let(:required_params) do
    {
      category: "Depositing content",
      name: "Rose Tyler",
      email: "rose@timetraveler.org",
      subject: "The Doctor",
      message: "Run."
    }
  end

  before { sign_in(user) }

  describe "#new" do
    subject { response }

    before { get :new }
    it { is_expected.to be_successful }
  end

  describe "#create" do
    subject { flash }

    before { post :create, params: { contact_form: params } }
    context "with the required parameters" do
      let(:params) { required_params }

      its(:notice) { is_expected.to eq("Thank you for your message!") }
    end

    context "without a category" do
      let(:params)  { required_params.except(:category) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Category can't be blank") }
    end

    context "without a name" do
      let(:params)  { required_params.except(:name) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Name can't be blank") }
    end

    context "without an email" do
      let(:params)  { required_params.except(:email) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Email can't be blank") }
    end

    context "without a subject" do
      let(:params)  { required_params.except(:subject) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Subject can't be blank") }
    end

    context "without a message" do
      let(:params)  { required_params.except(:message) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Message can't be blank") }
    end

    context "with an invalid email" do
      let(:params)  { required_params.merge(email: "bad-wolf") }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Email is invalid") }
    end
  end

  describe "#after_deliver" do
    context "with a successful email" do
      it "calls #after_deliver" do
        expect(controller).to receive(:after_deliver)
        post :create, params: { contact_form: required_params }
      end
    end
    context "with an unsuccessful email" do
      it "does not call #after_deliver" do
        expect(controller).not_to receive(:after_deliver)
        post :create, params: { contact_form: required_params.except(:email) }
      end
    end
  end

  context "when encountering a RuntimeError" do
    let(:msg_handler) { double("message handler") }

    before do
      allow(controller).to receive(:msg_handler).and_return msg_handler
      allow(msg_handler).to receive(:msg)
      expect(controller).to receive(:create).and_call_original
      allow(controller).to receive(:is_spam?).and_return false
      expect(controller).to receive(:contact_form_send_email).at_least(:once).and_return true
      expect(controller).to receive(:handle_create_exception).and_call_original
      expect(Hyrax::ContactMailer).to receive(:contact).and_raise(RuntimeError)
      expect(controller).to_not receive(:after_deliver)
    end
    it "is logged via Rails" do
      expect(msg_handler).to receive(:bold_error).with("Contact form failed to send: #<RuntimeError: RuntimeError>")
      post :create, params: { contact_form: required_params }
    end
  end

end
