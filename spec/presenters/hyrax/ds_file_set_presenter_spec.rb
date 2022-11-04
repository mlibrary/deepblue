require 'rails_helper'
require 'iiif_manifest'

RSpec.describe Hyrax::DsFileSetPresenter do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.ds_file_set_presenter_debug_verbose ).to eq debug_verbose }
    it { expect( described_class.ds_file_set_presenter_view_debug_verbose ).to eq false }
  end

  subject(:presenter) { described_class.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { Ability.new(user) }
  let(:attributes) { file.to_solr }
  let(:debug_verbose) {false}

  let(:file) do
    build( :file_set,
          id: '123abc',
          user: user,
          title: ["File title"],
          depositor: user.user_key,
          label: "filename.tif" )
  end
  let(:user) { create(:admin) }
  let(:user_key) { 'a_user_key' }
  let( :parent_id ) { '888888' }
  let( :parent_title ) { ['foo', 'bar'] }
  let(:parent_attributes) do
    { "id" => parent_id,
      "title_tesim" => parent_title,
      "human_readable_type_tesim" => ["DataSet Work"],
      "has_model_ssim" => ["DataSet"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key }
  end
  let( :parent_solr_document ) { SolrDocument.new( parent_attributes ) }
  let( :request ) { double(host: 'example.org', base_url: 'http://example.org') }
  let( :parent_presenter ) { Hyrax::DataSetPresenter.new( parent_solr_document, ability, request ) }
  let( :parent_data_set ) { create( :public_data_set, id: parent_id, user: user, title: parent_title ) }

  before do
    # parent_work.ordered_members << file
    allow( presenter ).to receive( :parent ).and_return parent_presenter
  end

  describe 'stats_path' do
    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(file).to receive(:persisted?).and_return(true)
    end
    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_file_path(id: file, locale: 'en') }
  end

  describe "#to_s" do
    subject { presenter.to_s }

    it { is_expected.to eq 'File title' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }

    it { is_expected.to eq 'File' }
  end

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }

    it { is_expected.to eq 'file_sets/file_set' }
  end

  describe "office_document?" do
    subject { presenter.office_document? }

    it { is_expected.to be false }
  end

  describe "#current_user_can_edit?" do
    subject { presenter.current_user_can_edit? }
    let( :current_ability ) { ability }
    let( :current_user ) { double( "current_user" ) }
    let( :email ) { "test@email.com" }
    before do
      allow( presenter ).to receive( :parent_data_set ).and_return parent_data_set
      allow( current_user ).to receive( :email ).and_return email
      allow( current_ability ).to receive( :current_user ).and_return current_user
    end

    context 'cannot when no current_user' do
      before do
        allow( current_ability ).to receive( :current_user ).and_return nil
      end
      it { is_expected.to be false }
    end
    context 'cannot when current user is not in parent can edit array' do
      before do
        allow( parent_data_set ).to receive( :edit_users ).and_return []
      end
      it { is_expected.to be false }
    end
    context 'can when current user is in parent can edit array' do
      before do
        allow( parent_data_set ).to receive( :edit_users ).and_return [email]
      end
      it { is_expected.to be true }
    end
  end

  describe "#can_delete_file?" do
    subject { presenter.can_delete_file? }
    let( :current_ability ) { ability }
    let ( :workflow ) { double( "workflow" ) }
    before do
      allow( presenter ).to receive( :parent_data_set ).and_return parent_data_set
    end

    context 'cannot when single-use show and admin' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return true
        allow( presenter ).to receive( :doi_minted? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return true
      end
      it { is_expected.to be false }
    end
    context 'cannot when single-use show and not admin' do
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
        allow( presenter ).to receive( :doi_minted? ).and_return true
        allow( current_ability ).to receive( :admin? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'can when admin and not single use show or doi minted' do
      before do
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( presenter ).to receive( :doi_minted? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return true
      end
      it { is_expected.to be true }
    end
  end

  describe "#can_download_file?" do
    subject { presenter.can_download_file? }
    let(:current_ability) { ability }

    context 'cannot when file size is too large' do
      before do
        expect( presenter ).to receive( :file_size_too_large_to_download? ).at_least(:once).and_return true
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :can? ).with( :download, presenter.id ).and_return true
      end
      it { is_expected.to be false }
    end
    context 'can when single-use show' do
      before do
        allow( presenter ).to receive( :file_size_too_large_to_download? ).and_return false
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
        allow( current_ability ).to receive( :can? ).with( :download, presenter.id ).and_return true
      end
      it { is_expected.to be true }
    end
    context 'can when user can download id' do
      before do
        allow( presenter ).to receive( :file_size_too_large_to_download? ).and_return false
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :download, presenter.id ).and_return true
      end
      it { is_expected.to be true }
    end
    context 'cannot when user cannot download id' do
      before do
        allow( presenter ).to receive( :file_size_too_large_to_download? ).and_return false
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :download, presenter.id ).and_return false
      end
      it { is_expected.to be false }
    end
  end

  describe "#can_edit_file?" do
    subject { presenter.can_edit_file? }
    let(:current_ability) { ability }
    let( :current_user ) { double( "current_user" ) }
    let ( :workflow ) { double( "workflow" ) }

    context 'cannot when tombstone present' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return "tombstoned"
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        allow( presenter ).to receive( :editor? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'cannot when single-use show' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
        allow( current_ability ).to receive( :admin? ).and_return false
        allow( presenter ).to receive( :editor? ).and_return false
      end
      it { is_expected.to be false }
    end
    context 'can when admin and not single-use show or tombstoned' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        expect( current_ability ).to receive( :admin? ).at_least(:once).and_return true
        allow( presenter ).to receive( :editor? ).and_return false
      end
      it { is_expected.to be true }
    end
    context 'can when editor and not deposited' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        expect( presenter ).to receive( :editor? ).at_least(:once).and_return true
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
      end
      it { is_expected.to be true }
    end
    context 'can when editor and doi present and not deposited' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        allow( parent_presenter ).to receive( :doi ).and_return "dsf"
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        expect( presenter ).to receive( :editor? ).at_least(:once).and_return true
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
      end
      it { is_expected.to be true }
    end
    context 'cannot when editor and doi present and deposited' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        allow( parent_presenter ).to receive( :doi ).and_return "dsf"
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        expect( presenter ).to receive( :editor? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "deposited"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
      end
      it { is_expected.to be false }
    end
    context 'cannot when not editor' do
      before do
        allow( parent_presenter ).to receive( :tombstone ).and_return nil
        allow( presenter ).to receive( :anonymous_show? ).and_return false
        allow( current_ability ).to receive( :admin? ).and_return false
        allow( presenter ).to receive( :editor? ).and_return false
        allow( workflow ).to receive( :state ).and_return "pending_review"
        allow( current_user ).to receive( :email ).and_return nil
        allow( current_ability ).to receive( :current_user ).and_return current_user
        allow( parent_presenter ).to receive( :workflow ).and_return workflow
      end
      it { is_expected.to be false }
    end
  end

  describe "#can_view_file?" do
    subject { presenter.can_view_file? }
    let(:current_ability) { ability }
    let ( :workflow ) { double( "workflow" ) }

    context 'cannot when tombstone present' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return "tombstoned"
      end
      it { is_expected.to be false }
    end
    context 'can when single-use show' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return true
      end
      it { is_expected.to be true }
    end
    context 'cannot when pending and visible and can not edit' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return false
        allow( solr_document ).to receive( :visibility ).and_return 'open'
        puts 'cannot when pending and visible and can not edit' if debug_verbose
      end
      it { is_expected.to be false }
    end
    context 'can when pending and visible and can edit' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        allow( workflow ).to receive( :state ).and_return "pending_review"
        allow( parent_presenter ).to receive( :workflow ).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return true
        allow( parent_presenter ).to receive( :embargoed? ).and_return false
        puts 'can when pending and visible and can edit' if debug_verbose
      end
      it { is_expected.to be true }
    end
    context 'can when embargoed and can edit' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        allow( workflow ).to receive( :state ).and_return "pending_review"
        allow( parent_presenter ).to receive( :workflow ).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return true
        allow( parent_presenter ).to receive( :embargoed? ).and_return true
        # TODO: expect( parent_presenter ).to receive( :embargoed? ).at_least(:once).and_return true
        puts 'can when embargoed and can edit' if debug_verbose
      end
      it { is_expected.to be true }
    end
    context 'cannot when embargoed and can not edit' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "pending_review"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return false
        expect( parent_presenter ).to receive( :embargoed? ).at_least(:once).and_return true
        puts 'cannot when embargoed and can not edit' if debug_verbose
      end
      it { is_expected.to be false }
    end
    context 'can when deposited and visible' do
      before do
        expect( parent_presenter ).to receive( :tombstone ).at_least(:once).and_return nil
        expect( presenter ).to receive( :anonymous_show? ).at_least(:once).and_return false
        expect( workflow ).to receive( :state ).at_least(:once).and_return "deposited"
        expect( parent_presenter ).to receive( :workflow ).at_least(:once).and_return workflow
        expect( current_ability ).to receive( :can? ).at_least(:once).with( :edit, presenter.id ).and_return false
        expect( solr_document ).to receive( :visibility ).at_least(:once).and_return 'open'
        puts 'can when deposited and visible' if debug_verbose
      end
      it { is_expected.to be true }
    end
  end

  describe "#user_can_perform_any_action?" do
    subject { presenter.user_can_perform_any_action? }
    let(:current_ability) { ability }

    context 'can when user can view file' do
      before do
        expect( presenter ).to receive( :can_view_file? ).and_return true
        allow( presenter ).to receive( :can_download_file? ).and_return false
        allow( presenter ).to receive( :can_edit_file? ).and_return false
        allow( presenter ).to receive( :can_delete_file? ).and_return false
      end
      it { is_expected.to be true }
    end
    context 'can when user can download file' do
      before do
        allow( presenter ).to receive( :can_view_file? ).and_return false
        expect( presenter ).to receive( :can_download_file? ).and_return true
        allow( presenter ).to receive( :can_edit_file? ).and_return false
        allow( presenter ).to receive( :can_delete_file? ).and_return false
      end
      it { is_expected.to be true }
    end
    context 'can when user can edit file' do
      before do
        allow( presenter ).to receive( :can_view_file? ).and_return false
        allow( presenter ).to receive( :can_download_file? ).and_return false
        expect( presenter ).to receive( :can_edit_file? ).and_return true
        allow( presenter ).to receive( :can_delete_file? ).and_return false
      end
      it { is_expected.to be true }
    end
    context 'can when user can delete file' do
      before do
        allow( presenter ).to receive( :can_view_file? ).and_return false
        allow( presenter ).to receive( :can_download_file? ).and_return false
        allow( presenter ).to receive( :can_edit_file? ).and_return false
        expect( presenter ).to receive( :can_delete_file? ).and_return true
      end
      it { is_expected.to be true }
    end
    context 'when user cannot perform any action' do
      before do
        expect( presenter ).to receive( :can_view_file? ).and_return false
        expect( presenter ).to receive( :can_download_file? ).and_return false
        expect( presenter ).to receive( :can_edit_file? ).and_return false
        expect( presenter ).to receive( :can_delete_file? ).and_return false
      end
      it { is_expected.to be false }
    end
  end

  describe "properties and methods delegated to solr_document" do
    let(:solr_properties) do
      [ "date_uploaded",
        "title_or_label",
        "contributor",
        "creator",
        "title",
        "description",
        "publisher",
        "subject",
        "language",
        "license",
        "format_label",
        # "file_size", # removed
        "height",
        "width",
        "filename",
        "well_formed",
        "page_count",
        "file_title",
        "last_modified",
        "checksum_algorithm",
        "checksum_value",
        "original_checksum",
        "mime_type",
        "duration",
        "sample_rate",
        "original_file_id"
      ] + %w(
        doi
        file_size
        original_checksum
        mime_type
        title
        virus_scan_service
        virus_scan_status
        virus_scan_status_date
      )
    end
    let(:solr_methods) do
       %i(
        date_created
        date_modified
        depositor
        doi_minted?
        doi_minting_enabled?
        doi_pending?
        fetch
        first
        has?
        itemtype
        keyword
        )
    end

    it "delegates properties to the solr_document" do
      solr_properties.each do |property|
        expect(solr_document).to receive(property.to_sym)
        presenter.send(property)
      end
    end

    it "delegates methods to the solr_document" do
      solr_methods.each do |method|
        # expect(solr_document).to receive(method)
        is_expected.to delegate_method(method).to(:solr_document)
      end
    end

    # it { is_expected.to delegate_method(:depositor).to(:solr_document) }
    # it { is_expected.to delegate_method(:keyword).to(:solr_document) }
    # it { is_expected.to delegate_method(:date_created).to(:solr_document) }
    # it { is_expected.to delegate_method(:date_modified).to(:solr_document) }
    # it { is_expected.to delegate_method(:itemtype).to(:solr_document) }
    # it { is_expected.to delegate_method(:fetch).to(:solr_document) }
    # it { is_expected.to delegate_method(:first).to(:solr_document) }
    # it { is_expected.to delegate_method(:has?).to(:solr_document) }
  end

  describe '#link_name' do
    context "with a user who can view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(true)
      end
      it "shows the title" do
        expect(presenter.link_name).to eq 'File title'
        expect(presenter.link_name).not_to eq 'filename.tif'
      end
    end

    context "with a user who cannot view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(false)
      end
      it "hides the title" do
        expect(presenter.link_name).to eq 'File title'
      end
    end
  end

  describe '#tweeter' do
    subject { presenter.tweeter }

    it 'delegates the depositor as the user_key to TwitterPresenter.call' do
      expect(Hyrax::TwitterPresenter).to receive(:twitter_handle_for).with(user_key: solr_document.depositor)
      subject
    end
  end

  describe "#event_class" do
    subject { presenter.event_class }

    it { is_expected.to eq 'FileSet' }
  end

  describe '#events' do
    subject(:events) { presenter.events }

    let(:event_stream) { double('event stream') }
    let(:response) { double('response') }

    before do
      allow(presenter).to receive(:event_stream).and_return(event_stream)
    end

    it 'calls the event store' do
      allow(event_stream).to receive(:fetch).with(100).and_return(response)
      expect(events).to eq response
    end
  end

  describe '#event_stream' do
    let(:object_stream) { double('object_stream') }

    it 'returns a Nest stream' do
      expect(Hyrax::RedisEventStore).to receive(:for).with(Nest).and_return(object_stream)
      presenter.send(:event_stream)
    end
  end

  describe "characterization" do
    describe "#characterization_metadata" do
      subject { presenter.characterization_metadata }

      it "only has set attributes are in the metadata" do
        expect(subject[:height]).to be_blank
        expect(subject[:page_count]).to be_blank
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it "only has set attributes are in the metadata" do
          expect(subject[:height]).not_to be_blank
          expect(subject[:page_count]).to be_blank
        end
      end
    end

    describe "#characterized?" do
      subject { presenter }

      it { is_expected.not_to be_characterized }

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it { is_expected.to be_characterized }
      end

      context "when file_format is set" do
        let(:attributes) { { file_format_tesim: ['format'] } }

        it { is_expected.to be_characterized }
      end
    end

    describe "#label_for_term" do
      subject { presenter.label_for_term(:titleized_key) }

      it { is_expected.to eq("Titleized Key") }
    end

    describe "with additional characterization metadata" do
      let(:additional_metadata) do
        {
          foo: ["bar"],
          fud: ["bars", "cars"]
        }
      end

      before { allow(presenter).to receive(:additional_characterization_metadata).and_return(additional_metadata) }
      subject { presenter }

      specify do
        expect(subject).to be_characterized
        expect(subject.characterization_metadata[:foo]).to contain_exactly("bar")
        expect(subject.characterization_metadata[:fud]).to contain_exactly("bars", "cars")
      end
    end

    describe "characterization values" do
      before { allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata) }

      context "with a limited set of short values" do
        let(:mock_metadata) { { term: ["asdf", "qwer"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("asdf", "qwer") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with a value set exceeding the configured amount" do
        let(:mock_metadata) { { term: ["1", "2", "3", "4", "5", "6", "7", "8"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", "7", "8") }
        end
      end

      context "with values exceeding 250 characters" do
        let(:mock_metadata) { { term: [("a" * 251), "2", "3", "4", "5", "6", ("b" * 251)] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly(("a" * 247) + "...", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", (("b" * 247) + "...")) }
        end
      end

      context "with a string as a value" do
        let(:mock_metadata) { { term: "string" } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("string") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with an integer as a value" do
        let(:mock_metadata) { { term: 1440 } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1440") }
        end
      end
    end
  end

  # TODO: activate these tests when we integrate IIIF
  # describe 'IIIF integration' do
  #   def uri_segment_escape(uri)
  #     ActionDispatch::Journey::Router::Utils.escape_segment(uri)
  #   end
  #
  #   let(:file_set) { create(:file_set) }
  #   let(:solr_document) { SolrDocument.new(file_set.to_solr) }
  #   let(:request) { double('request', base_url: 'http://test.host') }
  #   let(:presenter) { described_class.new(solr_document, ability, request) }
  #   let(:id) { ActiveFedora::File.uri_to_id(file_set.original_file.versions.last.uri) }
  #
  #   describe "#display_image" do
  #     subject { presenter.display_image }
  #
  #     context 'without a file' do
  #       let(:id) { 'bogus' }
  #
  #       it { is_expected.to be_nil }
  #     end
  #
  #     context 'with a file' do
  #       before do
  #         Hydra::Works::AddFileToFileSet.call(file_set,
  #                                             file_path, :original_file)
  #       end
  #
  #       context "when the file is not an image" do
  #         let(:file_path) { File.open(fixture_path + '/hyrax_generic_stub.txt') }
  #
  #         it { is_expected.to be_nil }
  #       end
  #
  #       context "when the file is an image" do
  #         let(:file_path) { File.open(fixture_path + '/world.png') }
  #
  #         before do
  #           allow(solr_document).to receive(:image?).and_return(true)
  #         end
  #
  #         it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
  #         its(:url) { is_expected.to eq "http://test.host/images/#{uri_segment_escape(id)}/full/600,/0/default.jpg" }
  #
  #         context 'with custom image size default' do
  #           let(:custom_image_size) { '666,' }
  #
  #           around do |example|
  #             default_image_size = Hyrax.config.iiif_image_size_default
  #             Hyrax.config.iiif_image_size_default = custom_image_size
  #             example.run
  #             Hyrax.config.iiif_image_size_default = default_image_size
  #           end
  #
  #           it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
  #           its(:url) { is_expected.to eq "http://test.host/images/#{uri_segment_escape(id)}/full/#{custom_image_size}/0/default.jpg" }
  #         end
  #
  #         context 'with custom image url builder' do
  #           let(:id) { file_set.original_file.id }
  #           let(:custom_builder) do
  #             ->(file_id, base_url, _size) { "#{base_url}/downloads/#{file_id.split('/').first}" }
  #           end
  #
  #           around do |example|
  #             default_builder = Hyrax.config.iiif_image_url_builder
  #             Hyrax.config.iiif_image_url_builder = custom_builder
  #             example.run
  #             Hyrax.config.iiif_image_url_builder = default_builder
  #           end
  #
  #           it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
  #           its(:url) { is_expected.to eq "http://test.host/downloads/#{id.split('/').first}" }
  #         end
  #
  #         context "when the user doesn't have permission to view the image" do
  #           let(:user) { create(:user) }
  #
  #           it { is_expected.to be_nil }
  #         end
  #       end
  #     end
  #   end
  #
  #   describe "#iiif_endpoint" do
  #     subject { presenter.send(:iiif_endpoint, id) }
  #
  #     before do
  #       allow(Hyrax.config).to receive(:iiif_image_server?).and_return(riiif_enabled)
  #       Hydra::Works::AddFileToFileSet.call(file_set,
  #                                           File.open(fixture_path + '/world.png'), :original_file)
  #     end
  #
  #     context 'with iiif_image_server enabled' do
  #       let(:riiif_enabled) { true }
  #
  #       its(:url) { is_expected.to eq "http://test.host/images/#{uri_segment_escape(id)}" }
  #       its(:profile) { is_expected.to eq 'http://iiif.io/api/image/2/level2.json' }
  #
  #       context 'with a custom iiif image profile' do
  #         let(:custom_profile) { 'http://iiif.io/api/image/2/level1.json' }
  #
  #         around do |example|
  #           default_profile = Hyrax.config.iiif_image_compliance_level_uri
  #           Hyrax.config.iiif_image_compliance_level_uri = custom_profile
  #           example.run
  #           Hyrax.config.iiif_image_compliance_level_uri = default_profile
  #         end
  #
  #         its(:profile) { is_expected.to eq custom_profile }
  #       end
  #     end
  #
  #     context 'with iiif_image_server disabled' do
  #       let(:riiif_enabled) { false }
  #
  #       it { is_expected.to be nil }
  #     end
  #   end
  # end

end
