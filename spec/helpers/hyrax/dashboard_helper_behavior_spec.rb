require 'rails_helper'

RSpec.describe Hyrax::DashboardHelperBehavior, type: :helper, skip: false do
  describe "#on_the_dashboard?" do
    it "returns false for controllers that aren't a part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "foo")
      expect(helper).not_to be_on_the_dashboard
    end

    it "returns true for controllers that are part of the dashboard" do
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/works")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/collections")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/highlights")
      expect(helper).to be_on_the_dashboard
      allow(helper).to receive(:params).and_return(controller: "hyrax/my/shares")
      expect(helper).to be_on_the_dashboard
    end
  end

  describe "#number_of_works" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models("DataSet", user1, user2)
    end

    it "finds 3 works" do
      expect(helper.number_of_works(user1)).to eq(3)
    end
  end

  describe "#number_of_files" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models("FileSet", user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_files(user1)).to eq(3)
    end
  end

  describe "#number_of_collections" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }

    before do
      create_models("Collection", user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_collections(user1)).to eq(3)
    end
  end

  def create_models(model, user1, user2)
    # deposited by the first user
    3.times do |t|
      conn.add id: "199#{t}", 'depositor_tesim' => user1.user_key, "has_model_ssim" => [model],
               'depositor_ssim' => user1.user_key
    end

    # deposited by the second user, but editable by the first
    conn.add id: "1994", 'depositor_tesim' => user2.user_key, "has_model_ssim" => [model],
             'depositor_ssim' => user2.user_key, "edit_access_person_ssim" => user1.user_key
    conn.commit
  end
end
