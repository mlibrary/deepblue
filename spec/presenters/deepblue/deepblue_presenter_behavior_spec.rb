require 'rails_helper'

class TestPresenter 
   include Deepblue::DeepbluePresenterBehavior
end


RSpec.describe Deepblue::DeepbluePresenterBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.deep_blue_presenter_behavior_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared all' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.deep_blue_presenter_behavior_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.deep_blue_presenter_behavior_debug_verbose = debug_verbose
      end
      context do

        let(:dummy_class) { double("dummy_class") }
        let(:member) { double("member") }

        before do
          allow(dummy_class).to receive(:action_mailer).and_return member
          allow(member).to receive(:default_url_options).and_return "options"

          allow(member).to receive(:id).and_return 'id'
          allow(member).to receive(:download_path_link).and_return "download_path_link"
          allow(member).to receive(:thumbnail_post_process).and_return "thumb"
          allow(dummy_class).to receive(:can_download_file?).and_return true
        end


        it "is TODO", skip: true do
          presenter = TestPresenter.new
          dc = presenter.default_url_options

          allow(Rails.application).to receive(:config).and_return dummy_class

          expect(dc).to eq("collid1")
        end

        it "generates a download path link" do
          presenter = TestPresenter.new
          dc = presenter.download_path_link main_app: dummy_class, curation_concern: member

          expect(dc).to eq("download_path_link")
        end

        it "presently does nothing" do
          presenter = TestPresenter.new
          dc = presenter.member_thumbnail_image_options member: nil

          expect(dc).to eq({})
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end

        it "returns a thumbnail url option" do
          presenter = TestPresenter.new
          dc = presenter.member_thumbnail_url_options dummy_class
          expect(dc).to eq({:suppress_link=>false})
        end

        it "generates a post post process" do
          presenter = TestPresenter.new
          dc = presenter.member_thumbnail_post_process main_app: nil, member: member, tag: "tag"
          expect(dc).to eq("thumb")
        end

      end
    end
    it_behaves_like 'shared all', false
    it_behaves_like 'shared all', true
  end

end
