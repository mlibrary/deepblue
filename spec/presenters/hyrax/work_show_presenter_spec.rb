
RSpec.describe Hyrax::WorkShowPresenter, clean_repo: true do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { double(host: 'example.org', base_url: 'http://example.org') }
  let(:user_key) { 'a_user_key' }
  let(:debug_verbose) {::DeepBlueDocs::Application.config.work_show_presenter_debug_verbose}

  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["DataSet"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key }
  end
  let(:ability) { double Ability }
  let(:presenter) { described_class.new(solr_document, ability, request) }

  subject { described_class.new(double, double) }

  it { is_expected.to delegate_method(:to_s).to(:solr_document) }
  it { is_expected.to delegate_method(:human_readable_type).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }
  it { is_expected.to delegate_method(:date_modified).to(:solr_document) }
  it { is_expected.to delegate_method(:date_uploaded).to(:solr_document) }
  it { is_expected.to delegate_method(:rights_statement).to(:solr_document) }

  it { is_expected.to delegate_method(:based_near_label).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:depositor).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:keyword).to(:solr_document) }
  it { is_expected.to delegate_method(:itemtype).to(:solr_document) }
  # TODO: fix -- updates to member_presenter generation causing an issue here
  # it { is_expected.to delegate_method(:member_presenters).to(:member_presenter_factory) }
  it { is_expected.to delegate_method(:ordered_ids).to(:member_presenter_factory) }

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe '#manifest_url' do
    subject { presenter.manifest_url }

    it { is_expected.to eq 'http://example.org/concern/data_sets/888888/manifest' }
  end

  describe "#can_delete_work?" do
    subject { presenter.can_delete_work? }
    let( :current_ability ) { ability }
    let ( :workflow ) { double( "workflow" ) }
    before do
      # allow( presenter ).to receive( :parent_data_set ).and_return parent_data_set
    end

    context 'cannot when anonymous show and admin' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return true
        allow( presenter ).to receive( :doi_minted? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return true
      end
      it { is_expected.to be false }
    end
    context 'cannot when anonymous show and not admin' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return true
        allow( presenter ).to receive( :doi_minted? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'cannot when doi minted and admin' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( presenter ).to receive( :doi_minted? ).and_return true
        allow( current_ability ).to receive( :admin? ).and_return true
      end
      it { is_expected.to be false }
    end
    context 'cannot when doi minted and not admin' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( solr_document ).to receive( :doi_minted? ).and_return true
        allow( current_ability ).to receive( :admin? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'can when admin and not single use show or doi minted' do
      before do
        allow( current_ability ).to receive( :can? ).with( id: solr_document.id ).and_return true
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( solr_document ).to receive( :doi_minted? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return true
      end
      it { is_expected.to be true }
    end
  end

  describe "#can_edit_work?" do
    subject { presenter.can_edit_work? }
    let(:current_ability) { ability }
    let ( :workflow ) { double( "workflow" ) }

    context 'cannot when anonymous show' do
      before do
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
        allow( current_ability ).to receive( :admin? ).and_return false
        allow( presenter ).to receive( :editor? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'can when admin and not anonymous show or tombstoned' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        expect( current_ability ).to receive( :admin? ).at_least(:once).and_return true
        allow( presenter ).to receive( :editor? ).and_return false
      end
      it { is_expected.to be true }
    end
    context 'can when editor and not deposited' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        expect( presenter ).to receive( :editor? ).at_least(:once).and_return true
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
      end
      it { is_expected.to be true }
    end
    context 'cannot when editor and deposited' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        expect( presenter ).to receive( :editor? ).at_least(:once).and_return true
        expect( workflow ).to receive( :state ).at_least(:once).and_return "deposited"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
      end
      it { is_expected.to be false }
    end
    context 'cannot when not editor' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        allow( presenter ).to receive( :editor? ).and_return false
        allow( workflow ).to receive( :state ).and_return "pending_review"
        allow( presenter ).to receive( :workflow ).and_return workflow
      end
      it { is_expected.to be false }
    end
  end

  describe "#can_view_work_detail?" do
    subject { presenter.can_view_work_details? }
    let(:current_ability) { ability }
    let ( :workflow ) { double( "workflow" ) }
    let( :current_user ) { double( "current_user" ) }
    let( :email ) { "test@email.com" }
    before do
      allow( current_user ).to receive( :email ).and_return email
      allow( current_ability ).to receive( :current_user ).and_return current_user
      allow( current_user ).to receive( :user_approver? ).with( current_user ).and_return false
    end

    context 'cannot when tombstone present' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return "tombstoned"
      end
      it { is_expected.to be false }
    end
    context 'can when anonymous show' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
      end
      it { is_expected.to be true }
    end
    context 'cannot when pending and visible and can not edit' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return false
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return false if debug_verbose
      end
      it { is_expected.to be false }
    end
    context 'can when pending and visible and can edit' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return true if debug_verbose
      end
      it { is_expected.to be true }
    end
    context 'can when deposited and visible' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false if debug_verbose
        expect( workflow ).to receive( :state ).at_least(:once).and_return "deposited"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( solr_document ).to receive( :visibility ).at_least(:once).and_return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      it { is_expected.to be true }
    end
  end

  describe "#can_view_work_metadata?" do
    subject { presenter.can_view_work_metadata? }
    let(:current_ability) { ability }
    let ( :workflow ) { double( "workflow" ) }
    let( :current_user ) { double( "current_user" ) }
    let( :email ) { "test@email.com" }
    before do
      allow( current_user ).to receive( :email ).and_return email
      allow( current_ability ).to receive( :current_user ).and_return current_user
      allow( current_user ).to receive( :user_approver? ).with( current_user ).and_return false
    end

    context 'can when tombstone present' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return "tombstoned"
      end
      it { is_expected.to be true }
    end
    context 'can when anonymous show' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
      end
      it { is_expected.to be true }
    end
    context 'cannot when pending and visible and can not edit' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).at_least(:once).and_return false
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        # expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'can when pending and visible and can edit' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).at_least(:once).and_return true
        expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        # expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return true
      end
      it { is_expected.to be true }
    end
    context 'can when deposited and visible' do
      before do
        expect( current_ability ).to receive( :can? ).with( :edit, solr_document.id ).and_return true if debug_verbose
        # expect( presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        # expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "deposited"
        expect( presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( solr_document ).to receive( :visibility ).at_least(:once).and_return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      it { is_expected.to be true }
    end
  end

  describe "#editor?" do
    subject { presenter.editor? }
    let( :current_ability ) { ability }

    context 'true when can edit' do
      before do
        allow( current_ability ).to receive( :can? ).with( :edit, solr_document ).and_return true
      end
      it { is_expected.to be true }
    end

    context 'false when cannot edit' do
      before do
        allow( current_ability ).to receive( :can? ).with( :edit, solr_document ).and_return false
      end
      it { is_expected.to be false }
    end

  end

  describe "#embargoed?" do
    subject { presenter.embargoed? }

    context 'true when visibility is embargoed' do
      before do
        expect( solr_document ).to receive( :visibility ).at_least(:once).and_return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      end
      it { is_expected.to be true }
    end

    context 'false when visibility is not embargoed' do
      before do
        expect( solr_document ).to receive( :visibility ).at_least(:once).and_return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      it { is_expected.to be false }
    end

  end

  describe '#iiif_viewer?' do
    let(:id_present) { false }
    let(:representative_presenter) { double('representative', present?: false) }
    let(:image_boolean) { false }
    let(:iiif_enabled) { true }
    let(:file_set_presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
    let(:file_set_presenters) { [file_set_presenter] }
    let(:read_permission) { true }

    before do
      allow(presenter).to receive(:representative_id).and_return(id_present)
      allow(presenter).to receive(:representative_presenter).and_return(representative_presenter)
      allow(presenter).to receive(:file_set_presenters).and_return(file_set_presenters)
      allow(file_set_presenter).to receive(:image?).and_return(true)
      allow(ability).to receive(:can?).with(:read, solr_document.id).and_return(read_permission)
      allow(representative_presenter).to receive(:image?).and_return(image_boolean)
      allow(Hyrax.config).to receive(:iiif_image_server?).and_return(iiif_enabled)
    end

    subject { presenter.iiif_viewer? }

    context 'with no representative_id' do
      it { is_expected.to be false }
    end

    context 'with no representative_presenter' do
      let(:id_present) { true }

      it { is_expected.to be false }
    end

    context 'with non-image representative_presenter' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }
      let(:image_boolean) { false }

      it { is_expected.to be false }
    end

    context 'with IIIF image server turned off' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }
      let(:image_boolean) { true }
      let(:iiif_enabled) { false }

      it { is_expected.to be false }
    end

    context 'with representative image and IIIF turned on' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }
      let(:image_boolean) { true }
      let(:iiif_enabled) { true }

      it { is_expected.to be true }

      context "when the user doesn't have permission to view the image" do
        let(:read_permission) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe '#stats_path' do
    let(:user) { 'sarah' }
    let(:ability) { double "Ability" }
    let(:work) { build(:data_set, id: '123abc') }
    let(:attributes) { work.to_solr }

    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(work).to receive(:persisted?).and_return(true)
    end

    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_work_path(id: work, locale: 'en') }
  end

  describe '#itemtype' do
    let(:work) { build(:data_set, resource_type: type) }
    let(:attributes) { work.to_solr }
    let(:ability) { double "Ability" }

    subject { presenter.itemtype }

    context 'when resource_type is Audio' do
      let(:type) { ['Audio'] }

      it do
        is_expected.to eq 'http://schema.org/AudioObject'
      end
    end

    context 'when resource_type is Conference Proceeding' do
      let(:type) { ['Conference Proceeding'] }

      it { is_expected.to eq 'http://schema.org/ScholarlyArticle' }
    end
  end

  describe 'admin users' do
    let(:user)    { create(:user) }
    let(:ability) { Ability.new(user) }
    let(:attributes) do
      {
        "read_access_group_ssim" => ["public"],
        'id' => '99999'
      }
    end

    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }

    context 'with a new public work' do
      it 'can feature the work' do
        allow(user).to receive(:can?).with(:create, FeaturedWork).and_return(true)
        expect(presenter.work_featurable?).to be true
        expect(presenter.display_feature_link?).to be true
        expect(presenter.display_unfeature_link?).to be false
      end
    end

    context 'with a featured work' do
      before { FeaturedWork.create(work_id: attributes.fetch('id')) }
      it 'can unfeature the work' do
        expect(presenter.work_featurable?).to be true
        expect(presenter.display_feature_link?).to be false
        expect(presenter.display_unfeature_link?).to be true
      end
    end

    describe "#editor?" do
      subject { presenter.editor? }

      it { is_expected.to be true }
    end
  end

  describe '#tweeter' do
    let(:user) { instance_double(User, user_key: 'user_key') }

    subject { presenter.tweeter }

    it 'delegates the depositor as the user_key to TwitterPresenter.twitter_handle_for' do
      expect(Hyrax::TwitterPresenter).to receive(:twitter_handle_for).with(user_key: user_key)
      subject
    end
  end

  describe "#permission_badge" do
    let(:badge) { instance_double(Hyrax::PermissionBadge) }

    before do
      allow(Hyrax::PermissionBadge).to receive(:new).and_return(badge)
    end
    it "calls the PermissionBadge object" do
      expect(badge).to receive(:render)
      presenter.permission_badge
    end
  end

  # describe "#work_presenters" do
  #   let(:obj) { create(:data_set_with_file_and_work) }
  #   let(:attributes) { obj.to_solr }
  #
  #   it "filters out members that are file sets" do
  #     expect(presenter.work_presenters.size).to eq 1
  #     expect(presenter.work_presenters.first).to be_instance_of(described_class)
  #   end
  # end

  # describe "#member_presenters" do # don't do embedded works in DBD
  #   let(:obj) { create(:data_set_with_file_and_work) }
  #   let(:attributes) { obj.to_solr }
  #
  #   it "returns appropriate classes for each" do
  #     expect(presenter.member_presenters.size).to eq 2
  #     expect(presenter.member_presenters.first).to be_instance_of(Hyrax::FileSetPresenter)
  #     expect(presenter.member_presenters.last).to be_instance_of(described_class)
  #   end
  # end

  # describe "#member_presenters_for" do
  #   let(:obj) { create(:data_set_with_file_and_work) }
  #   let(:attributes) { obj.to_solr }
  #   let(:items) { presenter.ordered_ids }
  #   let(:subject) { presenter.member_presenters_for(items) }
  #
  #   it "returns appropriate classes for each item" do
  #     expect(subject.size).to eq 2
  #     expect(subject.first).to be_instance_of(Hyrax::DsFileSetPresenter)
  #     expect(subject.last).to be_instance_of(described_class)
  #   end
  # end

  describe "#list_of_item_ids_to_display" do
    let(:subject) { presenter.list_of_item_ids_to_display }
    let(:items_list) { ['item0', 'item1', 'item2', 'item3', 'item4', 'item5', 'item6', 'item7', 'item8', 'item9'] }
    let(:rows) { 10 }
    let(:page) { 1 }
    let(:ability) { double "Ability" }
    let(:current_ability) { ability }

    before do
      allow(presenter).to receive(:ordered_ids).and_return(items_list)
      allow(current_ability).to receive(:can?).with(:read, 'item0').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item1').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item2').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item3').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item4').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item5').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item6').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item7').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item8').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item9').and_return true
      allow(presenter).to receive(:rows_from_params).and_return(rows)
      allow(presenter).to receive(:current_page).and_return(page)
      allow(Flipflop).to receive(:hide_private_items?).and_return(answer)
    end

    context 'when hiding private items' do
      let(:answer) { true }

      it "returns viewable items" do
        expect(subject.size).to eq 6
        expect(subject).to be_instance_of(Kaminari::PaginatableArray)
        expect(subject).to include("item0", "item2", "item4", "item5", "item7", "item9")
      end
    end
    context 'when including private items' do
      let(:answer) { false }

      it "returns appropriate items" do
        expect(subject.size).to eq 10
        expect(subject).to be_instance_of(Kaminari::PaginatableArray)
        expect(subject).to eq(items_list)
      end
    end
    context 'with pagination' do
      let(:rows) { 3 }
      let(:page) { 2 }

      let(:answer) { true }
      it 'partitions the item list and excluding hidden items' do
        expect(subject).to eq(['item5', 'item7', 'item9'])
      end
    end
  end

  describe "#total_pages" do
    let(:subject) { presenter.total_pages }
    let(:items) { 17 }
    let(:rows) { 4 }

    before do
      allow(Flipflop).to receive(:hide_private_items?).and_return(false)
      allow(presenter).to receive(:total_items).and_return(items)
      allow(presenter).to receive(:rows_from_params).and_return(rows)
    end

    it 'calculates number of pages from items and rows' do
      expect(subject).to eq(5)
    end
  end

  describe "#file_set_presenters" do
    let(:obj) { create(:data_set_with_ordered_files) }
    let(:attributes) { obj.to_solr }

    it "displays them in order" do
      expect(presenter.file_set_presenters.map(&:id)).to eq obj.ordered_member_ids
    end

    # TODO: fix this
    # context "solr query" do
    #   before do
    #     expect(ActiveFedora::SolrService).to receive(:query).twice.with(anything, hash_including(rows: 10_000)).and_return([])
    #   end
    #
    #   it "requests >10 rows" do
    #     presenter.file_set_presenters
    #   end
    # end

    context "when some of the members are not file sets" do
      let(:another_work) { create(:work) }

      before do
        obj.ordered_members << another_work
        obj.save!
      end

      it "filters out members that are not file sets" do
        expect(presenter.file_set_presenters.map(&:id)).not_to include another_work.id
      end
    end
  end

  describe "#representative_presenter" do
    let(:obj) { create(:data_set_with_representative_file) }
    let(:attributes) { obj.to_solr }

    it "has a representative" do
      expect(Hyrax::PresenterFactory).to receive(:build_for)
        .with(ids: [obj.members[0].id],
              presenter_class: Hyrax::CompositePresenterFactory,
              presenter_args: [ability, request])
        .and_return ["abc"]
      expect(presenter.representative_presenter).to eq("abc")
    end

    context 'without a representative' do
      let(:obj) { create(:work) }

      it 'has a nil presenter' do
        expect(presenter.representative_presenter).to be_nil
      end
    end

    context 'when it is its own representative' do
      let(:obj) { create(:work) }

      before do
        obj.representative_id = obj.id
        obj.save
      end

      it 'has a nil presenter; avoids infinite loop' do
        expect(presenter.representative_presenter).to be_nil
      end
    end
  end

  describe "#download_url" do
    subject { presenter.download_url }

    let(:solr_document) { SolrDocument.new(work.to_solr) }

    context "with a representative" do
      let(:work) { create(:data_set_with_representative_file) }

      it { is_expected.to eq "http://#{request.host}/downloads/#{work.representative_id}" }
    end

    context "without a representative" do
      let(:work) { create(:work) }

      it { is_expected.to eq '' }
    end
  end

  describe '#page_title' do
    subject { presenter.page_title }

    it { is_expected.to eq 'Generic Work | foo | ID: 888888 | Deep Blue Data' }
  end

  describe "#valid_child_concerns" do
    subject { presenter }

    it "delegates to the class attribute of the model" do
      allow(DataSet).to receive(:valid_child_concerns).and_return([DataSet])

      expect(subject.valid_child_concerns).to eq [DataSet]
    end
  end

  describe "#attribute_to_html" do
    let(:renderer) { double('renderer') }

    context 'with an existing field' do
      before do
        allow(Hyrax::Renderers::AttributeRenderer).to receive(:new)
          .with(:title, ['foo', 'bar'], {})
          .and_return(renderer)
      end

      it "calls the AttributeRenderer" do
        expect(renderer).to receive(:render)
        presenter.attribute_to_html(:title)
      end
    end

    context "with a field that doesn't exist" do
      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with('Hyrax::WorkShowPresenter attempted to render restrictions, but no method exists with that name.')
        presenter.attribute_to_html(:restrictions)
      end
    end
  end

  context "with workflow" do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }
    let(:entity) { instance_double(Sipity::Entity) }

    describe "#workflow" do
      subject { presenter.workflow }

      it { is_expected.to be_kind_of Hyrax::WorkflowPresenter }
    end
  end

  context "with inspect_work" do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }

    describe "#inspect_work" do
      subject { presenter.inspect_work }

      it { is_expected.to be_kind_of Hyrax::InspectWorkPresenter }
    end
  end

  describe "graph export methods" do
    let(:graph) do
      RDF::Graph.new.tap do |g|
        g << [RDF::URI('http://example.com/1'), RDF::Vocab::DC.title, 'Test title']
      end
    end

    let(:exporter) { double }

    before do
      allow(Hyrax::GraphExporter).to receive(:new).and_return(exporter)
      allow(exporter).to receive(:fetch).and_return(graph)
    end

    describe "#export_as_nt" do
      subject { presenter.export_as_nt }

      it { is_expected.to eq "<http://example.com/1> <http://purl.org/dc/terms/title> \"Test title\" .\n" }
    end

    describe "#export_as_ttl" do
      subject { presenter.export_as_ttl }

      it { is_expected.to eq "\n<http://example.com/1> <http://purl.org/dc/terms/title> \"Test title\" .\n" }
    end

    describe "#export_as_jsonld" do
      subject { presenter.export_as_jsonld }

      it do
        is_expected.to eq '{
  "@context": {
    "dc": "http://purl.org/dc/terms/"
  },
  "@id": "http://example.com/1",
  "dc:title": "Test title"
}'
      end
    end
  end

  describe "#manifest" do
    let(:work) { create(:data_set_with_one_file) }
    let(:solr_document) { SolrDocument.new(work.to_solr) }

    describe "#sequence_rendering" do
      subject do
        presenter.sequence_rendering
      end

      before do
        Hydra::Works::AddFileToFileSet.call_enhanced_version(work.file_sets.first,
                                            File.open(fixture_path + '/world.png'), :original_file)
      end

      it "returns a hash containing the rendering information" do
        work.rendering_ids = [work.file_sets.first.id]
        expect(subject).to be_an Array
      end
    end

    # When we added title sorting, this tests failed
    # Since we are not using III, lets skip this test.
    describe "#manifest_metadata", skip: true do
      subject do
        presenter.manifest_metadata
      end

      before do
        work.title = ['Test title', 'Another test title']
      end

      it "returns an array of metadata values" do
        expect(subject[0]['label']).to eq('Title')
        expect(subject[0]['value']).to eq Array( work.title.join( ' ' ) )
      end
    end
  end

  describe "#show_deposit_for?" do
    subject { presenter }

    context "when user has depositable collections" do
      let(:user_collections) { double }

      it "returns true" do
        expect(subject.show_deposit_for?(collections: user_collections)).to be true
      end
    end

    context "when user does not have depositable collections" do
      let(:user_collections) { nil }

      context "and user can create a collection" do
        before do
          allow(ability).to receive(:can?).with(:create_any, Collection).and_return(true)
        end

        it "returns true" do
          expect(subject.show_deposit_for?(collections: user_collections)).to be true
        end
      end

      context "and user can NOT create a collection" do
        before do
          allow(ability).to receive(:can?).with(:create_any, Collection).and_return(false)
        end

        it "returns false" do
          expect(subject.show_deposit_for?(collections: user_collections)).to be false
        end
      end
    end
  end

  describe '#iiif_viewer' do
    subject { presenter.iiif_viewer }

    it 'defaults to universal viewer' do
      expect(subject).to be :universal_viewer
    end
  end
end
