# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Actors::Orcid::PublishWorkActor do
  subject(:actor) { described_class.new(Hyrax::Actors::Terminator.new) }
  let(:user) { create(:user, :with_orcid_identity) }
  let(:ability) { Ability.new(user) }
  let(:attributes) { {} }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  #let(:next_actor) { Hyrax::Actors::Terminator.new }
  let(:model_class) { DataSet }
  let(:work) { model_class.create(work_attributes) }
  let(:work_attributes) do
    {
      "title" => ["Moomin"],
      "creator" => [
        [{
          "creator_name" => "Joan Smith",
          "creator_orcid" => orcid_id
        }].to_json
      ],
      "keyword" => ["a keyword"],
      "rights_statement" => ["http://rightsstatements.org/vocab/InC-OW-EU/1.0/"]
    }
  end
  let(:orcid_id) { user.orcid_identity.orcid_id }

  before do
    work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

    allow(Flipflop).to receive(:enabled?).and_call_original
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(::Hyrax::OrcidIntegrationService).to receive(:active_job_type).and_return :perform_now

    ActiveJob::Base.queue_adapter = :test
  end

  describe "#create" do
    before do
      allow(Hyrax::Orcid::IdentityStrategyDelegatorJob).to receive(:perform_now).with(work)
      allow(Hyrax::Orcid::IdentityStrategyDelegator).to receive(:new).with(work)

      actor.create(env)
    end

    context "when hyrax_orcid is enabled" do
      it "performs a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegatorJob).to have_received(:perform_now).with(work)
      end
    end

    context "when hyrax_orcid is disabled" do
      before do
        allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
        allow(Flipflop).to receive(:hyrax_orcid?).and_return false
      end

      it "does not enqueue a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegator).not_to have_received(:new).with(work)
      end
    end

    context "when the work is private" do
      before do
        work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      it "does not enqueue a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegator).not_to have_received(:new).with(work)
      end
    end
  end

  describe "#update" do
    before do
      allow(Hyrax::Orcid::IdentityStrategyDelegatorJob).to receive(:perform_now).with(work)
      allow(Hyrax::Orcid::IdentityStrategyDelegator).to receive(:new).with(work)

      actor.update(env)
    end

    context "when hyrax_orcid is enabled" do
      it "performs a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegatorJob).to have_received(:perform_now).with(work)
      end
    end

    context "when hyrax_orcid is disabled" do
      before do
        allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(false)
        allow(Flipflop).to receive(:hyrax_orcid?).and_return false
      end

      it "does not enqueue a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegator).not_to have_received(:new).with(work)
      end
    end

    context "when the work is private" do
      before do
        work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      it "does not enqueue a job" do
        expect(Hyrax::Orcid::IdentityStrategyDelegator).not_to have_received(:new).with(work)
      end
    end
  end

  describe "visible?" do
    context "when the work is public" do
      it "is true" do
        expect(actor.send(:visible?, env)).to be_truthy
      end
    end

    context "when the work is private" do
      before do
        work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      it "is false" do
        expect(actor.send(:visible?, env)).to be_falsey
      end
    end

    context "when the work is restricted to the institution" do
      before do
        work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end

      it "is false" do
        expect(actor.send(:visible?, env)).to be_falsey
      end
    end
  end
end
