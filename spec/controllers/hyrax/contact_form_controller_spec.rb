require 'rails_helper'

RSpec.describe Hyrax::ContactFormController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.contact_form_controller_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect( described_class::ALL_LOCAL                  ).eq false   }
    it { expect( described_class::NGR_JUST_HUMAN_TEST        ).eq false   }
    it { expect( described_class.contact_form_log_delivered  ).to eq true }
    it { expect( described_class.contact_form_log_spam       ).to eq true }
    it { expect( described_class.antispam_timeout_in_seconds ).to eq 8    }
  end

  let(:user) { create(:user) }
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
    it { is_expected.to be_success }
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
    let(:logger) { double(info?: true) }

    before do
      allow(controller).to receive(:logger).and_return(logger)
      allow(Hyrax::ContactMailer).to receive(:contact).and_raise(RuntimeError)
    end
    it "is logged via Rails" do
      # expect(logger).to receive(:error).with("Contact form failed to send: #<RuntimeError: RuntimeError>")
      expect(::Deepblue::LoggingHelper ).to receive(:bold_error).with("Contact form failed to send: #<RuntimeError: RuntimeError>")
      post :create, params: { contact_form: required_params }
    end
  end

end
