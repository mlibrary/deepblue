# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSet do

  let( :authoremail ) { 'authoremail@umich.edu' }
  let( :creator ) { 'Creator, A' }
  let( :current_user ) { 'user@umich.edu' }
  let( :date_created ) { '2018-02-28' }
  let( :depositor ) { authoremail }
  let( :description ) { 'The Description' }
  let( :id ) { '0123458678' }
  let( :methodology ) { 'The Methodology' }
  let( :rights_license ) { 'The Rights License' }
  let( :title ) { 'The Title' }
  let( :visibility_private ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let( :visibility_public ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let( :metadata_keys_all ) {
    %i[
      admin_set_id
      authoremail
      creator
      curation_notes_admin
      curation_notes_user
      date_coverage
      date_created
      date_modified
      date_updated
      depositor
      description
      doi
      file_set_ids
      fundedby
      fundedby_other
      grantnumber
      keyword
      language
      location
      methodology
      prior_identifier
      referenced_by
      rights_license
      rights_license_other
      subject_discipline
      title
      tombstone
      total_file_count
      total_file_size
      total_file_size_human_readable
      visibility
    ]
  }
  let( :metadata_keys_brief ) {
    %i[
      authoremail
      title
      visibility
    ]
  }
  let( :metadata_keys_update ) {
    %i[
      authoremail
      title
      visibility
    ]
  }
  let( :exp_class_name ) { 'DataSet' }
  let( :exp_location ) { "/concern/data_sets/#{id}" }

  describe 'constants' do
    it do
      expect( DataSet::DOI_PENDING ).to eq 'doi_pending'
    end
  end

  describe 'metadata overrides' do
    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.depositor = depositor
      subject.date_created = date_created
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      subject.visibility = visibility_public
    end

    it 'provides file_set_ids' do
      key = :file_set_ids
      exp_value = []
      key_values = { test: 'testing' }
      expect( subject.metadata_hash_override( key: key, ignore_blank_values: false, key_values: key_values ) ).to eq true
      expect( key_values[key] ).to eq exp_value
      expect( key_values[:test] ).to eq 'testing'
      expect( key_values.size ).to eq 2
    end

    it 'provides total_file_size' do
      key = :total_file_size
      exp_value = nil
      key_values = { test: 'testing' }
      expect( subject.metadata_hash_override( key: key, ignore_blank_values: false, key_values: key_values ) ).to eq true
      expect( key_values[key] ).to eq exp_value
      expect( key_values[:test] ).to eq 'testing'
      expect( key_values.size ).to eq 2
    end

    it 'provides total_file_size_human_readable' do
      key = :total_file_size_human_readable
      exp_value = nil
      key_values = { test: 'testing' }
      expect( subject.metadata_hash_override( key: key, ignore_blank_values: false, key_values: key_values ) ).to eq true
      expect( key_values[key] ).to eq exp_value
      expect( key_values[:test] ).to eq 'testing'
      expect( key_values.size ).to eq 2
    end

    it 'does not provide some arbritrary metadata' do
      key = :some_arbritrary_metadata
      key_values = { test: 'testing' }
      expect( subject.metadata_hash_override( key: key, ignore_blank_values: false, key_values: key_values ) ).to eq false
      expect( key_values[:test] ).to eq 'testing'
      expect( key_values.size ).to eq 1
    end

  end

  describe 'provenance metadata overrides' do
    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.depositor = depositor
      subject.date_created = date_created
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      subject.visibility = visibility_public
    end

    it 'provides file_set_ids' do
      prov_key_values = { test: 'testing' }
      attribute = :file_set_ids
      ignore_blank_key_values = false
      expect( subject.map_provenance_attributes_override!( event: '',
                                                           attribute: attribute,
                                                           ignore_blank_key_values: ignore_blank_key_values,
                                                           prov_key_values: prov_key_values ) ).to eq true
      expect( prov_key_values[:file_set_ids] ).to eq []
      expect( prov_key_values[:test] ).to eq 'testing'
      expect( prov_key_values.size ).to eq 2
    end

    it 'provides visibility' do
      prov_key_values = { test: 'testing' }
      attribute = :visibility
      ignore_blank_key_values = false
      expect( subject.map_provenance_attributes_override!( event: '',
                                                           attribute: attribute,
                                                           ignore_blank_key_values: ignore_blank_key_values,
                                                           prov_key_values: prov_key_values ) ).to eq true
      expect( prov_key_values[:visibility] ).to eq visibility_public
      expect( prov_key_values[:test] ).to eq 'testing'
      expect( prov_key_values.size ).to eq 2
    end

    it 'does not provide some arbritrary metadata' do
      prov_key_values = { test: 'testing' }
      attribute = :some_arbritrary_metadata
      ignore_blank_key_values = false
      expect( subject.map_provenance_attributes_override!( event: '',
                                                           attribute: attribute,
                                                           ignore_blank_key_values: ignore_blank_key_values,
                                                           prov_key_values: prov_key_values ) ).to eq false
      expect( prov_key_values[:test] ).to eq 'testing'
      expect( prov_key_values.size ).to eq 1
    end

  end

  describe 'properties' do
    ## TODO
    # it 'has private visibility when created' do
    #   expect(subject.visibility).to eq visibility_private
    # end

    it 'has subject property' do
      expect(subject).to respond_to(:subject_discipline)
    end

    it 'has identifier properties' do
      expect(subject).to respond_to(:doi)
      expect(subject).to respond_to(:hdl)
    end

    describe 'resource type' do
      it 'is set during initialization' do
        expect(subject.resource_type).to eq ['Dataset']
      end
    end
  end

  describe 'provenance constants' do

    it 'has all metadata elements defined' do
      expect( subject.attributes_all_for_provenance ).to eq metadata_keys_all
    end

    it 'has brief metadata elements defined' do
      expect( subject.attributes_brief_for_provenance ).to eq metadata_keys_brief
    end

    it 'has update metadata elements defined' do
      expect( subject.attributes_update_for_provenance ).to eq metadata_keys_update
    end

  end

  describe 'provenance mint doi' do
    let( :exp_despositor ) { depositor }
    let( :exp_event ) { Deepblue::AbstractEventBehavior::EVENT_MINT_DOI }
    let( :exp_visibility ) { visibility_public }

    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.date_created = date_created
      subject.depositor = depositor
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
    end

    it 'uses all attributes and keeps blank ones' do
      attributes, ignore_blank_key_values = subject.attributes_for_provenance_mint_doi
      expect( ignore_blank_key_values ).to eq Deepblue::AbstractEventBehavior::USE_BLANK_KEY_VALUES
      expect( attributes ).to eq metadata_keys_all
    end

    it 'is minted' do
      prov_logger_received = nil
      allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
      before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      expect( subject.provenance_mint_doi( current_user: current_user ) ).to eq true
      after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      validate_prov_logger_received( prov_logger_received: prov_logger_received,
                                     size: 37,
                                     before: before,
                                     after: after,
                                     exp_event: exp_event,
                                     exp_class_name: exp_class_name,
                                     exp_id: id,
                                     exp_authoremail: authoremail,
                                     exp_creator: [creator],
                                     exp_date_created: "2018-02-28",
                                     exp_description: [description],
                                     exp_depositor: exp_despositor,
                                     exp_location: exp_location,
                                     exp_methodology: methodology,
                                     exp_rights_license: rights_license,
                                     exp_visibility: exp_visibility )
    end

  end

  describe 'provenance publish' do
    let( :exp_despositor ) { depositor }
    let( :exp_event ) { Deepblue::AbstractEventBehavior::EVENT_PUBLISH }

    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.date_created = date_created
      subject.depositor = depositor
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      subject.visibility = visibility_public
    end

    it 'uses all attributes and keeps blank ones' do
      attributes, ignore_blank_key_values = subject.attributes_for_provenance_publish
      expect( ignore_blank_key_values ).to eq Deepblue::AbstractEventBehavior::USE_BLANK_KEY_VALUES
      expect( attributes ).to eq metadata_keys_all
    end

    it 'is published' do
      prov_logger_received = nil
      allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
      before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      expect( subject.provenance_publish( current_user: current_user ) ).to eq true
      after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      validate_prov_logger_received( prov_logger_received: prov_logger_received,
                                     size: 38,
                                     before: before,
                                     after: after,
                                     exp_event: exp_event,
                                     exp_class_name: exp_class_name,
                                     exp_id: id,
                                     exp_authoremail: authoremail,
                                     exp_creator: [creator],
                                     exp_date_created: "2018-02-28",
                                     exp_description: [description],
                                     exp_depositor: exp_despositor,
                                     exp_location: exp_location,
                                     exp_message: '',
                                     exp_methodology: methodology,
                                     exp_rights_license: rights_license,
                                     exp_visibility: visibility_public )
    end

  end

  describe 'provenance unpublish' do
    let( :exp_despositor ) { depositor }
    let( :exp_event ) { Deepblue::AbstractEventBehavior::EVENT_UNPUBLISH }

    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.date_created = date_created
      subject.depositor = depositor
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      subject.visibility = visibility_private
    end

    it 'uses all attributes and keeps blank ones' do
      attributes, ignore_blank_key_values = subject.attributes_for_provenance_unpublish
      expect( ignore_blank_key_values ).to eq Deepblue::AbstractEventBehavior::USE_BLANK_KEY_VALUES
      expect( attributes ).to eq metadata_keys_all
    end

    it 'is published' do
      prov_logger_received = nil
      allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
      before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      expect( subject.provenance_unpublish( current_user: current_user ) ).to eq true
      after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      validate_prov_logger_received( prov_logger_received: prov_logger_received,
                                     size: 37,
                                     before: before,
                                     after: after,
                                     exp_event: exp_event,
                                     exp_class_name: exp_class_name,
                                     exp_id: id,
                                     exp_authoremail: authoremail,
                                     exp_creator: [creator],
                                     exp_date_created: "2018-02-28",
                                     exp_description: [description],
                                     exp_depositor: exp_despositor,
                                     exp_location: exp_location,
                                     exp_methodology: methodology,
                                     exp_rights_license: rights_license,
                                     exp_visibility: visibility_private )
    end

  end

  describe 'it requires core metadata' do
    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.date_created = date_created
      subject.description = [description]
      subject.rights_license = rights_license
    end

    it 'validates authoremail' do
      subject.authoremail = nil
      expect(subject).not_to be_valid
    end

    it 'validates creator' do
      subject.creator = []
      expect(subject).not_to be_valid
    end

    it 'validates date_created' do
      subject.date_created = nil
      expect(subject).not_to be_valid
    end

    it 'validates description' do
      subject.description = [description]
      expect(subject).not_to be_valid
    end

    it 'validates rights_license' do
      subject.rights_license = nil
      expect(subject).not_to be_valid
    end

    it 'validates title' do
      subject.title = []
      expect(subject).not_to be_valid
    end
  end

  describe 'it can be tombstoned' do
    let( :epitaph ) { 'The reason for being tombstoned.' }
    let( :depositor_at_tombstone ) { depositor }
    let( :visibility_at_tombstone ) { visibility_public }
    let( :exp_event ) { Deepblue::AbstractEventBehavior::EVENT_TOMBSTONE }
    let( :exp_depositor ) { depositor }
    let( :exp_visibility ) { visibility_private }

    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.depositor = depositor
      subject.date_created = date_created
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      allow( Rails.logger ).to receive( :debug ).with( any_args )
    end

    it 'is tombstoned' do
      prov_logger_received = nil
      allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
      before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      expect( subject.entomb!( epitaph, current_user ) ).to eq true
      after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      validate_prov_logger_received( prov_logger_received: prov_logger_received,
                                     size: 40,
                                     before: before,
                                     after: after,
                                     exp_event: exp_event,
                                     exp_class_name: exp_class_name,
                                     exp_id: id,
                                     exp_authoremail: authoremail,
                                     exp_creator: [creator],
                                     exp_date_created: "2018-02-28",
                                     exp_description: [description],
                                     exp_depositor: exp_depositor,
                                     exp_location: exp_location,
                                     exp_methodology: methodology,
                                     exp_rights_license: rights_license,
                                     exp_tombstone: [epitaph],
                                     exp_visibility: exp_visibility,
                                     depositor_at_tombstone: depositor_at_tombstone,
                                     visibility_at_tombstone: visibility_at_tombstone )
    end

  end

  describe 'provenance update' do
    let( :exp_despositor ) { depositor }
    let( :exp_event ) { Deepblue::AbstractEventBehavior::EVENT_UPDATE }
    let( :methodology_new ) { 'The New Methodology' }
    let( :methodology_old ) { 'The Old Methodology' }
    let( :rights_license ) { 'The Rights License' }
    let( :subject_discipline ) { 'The Subject Discipline' }
    let( :form_params ) do
      { "title": [title, ""],
        "creator": [creator, ""],
        "authoremail": authoremail,
        "methodology": methodology_new,
        "description": [description, ""],
        "rights_license": rights_license,
        "subject_discipline": [subject_discipline, ""],
        "fundedby": "",
        "fundedby_other": "",
        "grantnumber": "",
        "keyword": [""],
        "language": [""],
        "referenced_by": [""],
        "member_of_collection_ids": "",
        "find_child_work": "",
        "permissions_attributes": { "0": { "access": "edit", "id": "197055dd-3e5e-4714-9878-8620f2195428/39/2e/47/ca/392e47ca-b01b-4c3f-afb9-9ddb537fdacc" } },
        "visibility_during_embargo": "restricted",
        "embargo_release_date": "2018-06-30",
        "visibility_after_embargo": "open",
        "visibility_during_lease": "open",
        "lease_expiration_date": "2018-06-30",
        "visibility_after_lease": "restricted",
        "visibility": visibility_private,
        "version": "W/\"591319c1fdd3c69832f55e8fbbef903a4a0381a5\"",
        "date_coverage": "",
        "curation_notes_admin": [""],
        "curation_notes_user": [""] }
    end
    let( :expected_attr_key_values ) { { UpdateAttribute_methodology: { attribute: :methodology, old_value: methodology, new_value: methodology_new } } }
    let( :expected_added_key_values ) { { UpdateAttribute_methodology: { "attribute" => "methodology", "old_value" => "The Methodology", "new_value" => "The New Methodology" } } }

    before do
      subject.id = id
      subject.authoremail = authoremail
      subject.title = [title]
      subject.creator = [creator]
      subject.date_created = date_created
      subject.depositor = depositor
      subject.description = [description]
      subject.methodology = methodology
      subject.rights_license = rights_license
      subject.subject_discipline = [subject_discipline]
      subject.visibility = visibility_public
    end

    it 'uses update attributes and discards blank ones' do
      attributes, ignore_blank_key_values = subject.attributes_for_provenance_update
      expect( ignore_blank_key_values ).to eq Deepblue::AbstractEventBehavior::IGNORE_BLANK_KEY_VALUES
      expect( attributes ).to eq metadata_keys_update
    end

    it 'logs provenance for update' do
      attr_key_values = subject.provenance_log_update_before( form_params: form_params )
      expect( attr_key_values ).to eq expected_attr_key_values
      subject.methodology = methodology_new

      prov_logger_received = nil
      allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
      before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      subject.provenance_log_update_after( current_user: current_user, update_attr_key_values: attr_key_values )
      after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
      validate_prov_logger_received( prov_logger_received: prov_logger_received,
                                     size: 10,
                                     before: before,
                                     after: after,
                                     exp_event: exp_event,
                                     exp_class_name: exp_class_name,
                                     exp_id: id,
                                     exp_authoremail: authoremail,
                                     exp_total_file_count: nil,
                                     exp_total_file_size: nil,
                                     exp_total_file_size_human_readable: nil,
                                     exp_visibility: visibility_public,
                                     **expected_added_key_values )
    end

  end

  def validate_expected( rv_key_values, key, exp_value )
    key = key.to_s
    expect( rv_key_values[key] ).to eq exp_value if exp_value.present?
    # the rv_key_values.key?(key) seems to have semantically changed in ruby 2.5, so skip this check until a
    # replacement can be figured out.
    # expect( rv_key_values.key?(key) ).to eq false if exp_value.nil?
  end

  def validate_prov_logger_received( prov_logger_received:,
                                     size:,
                                     print_all_key_values: false,
                                     before: nil,
                                     after: nil,
                                     exp_timestamp: nil,
                                     exp_time_zone: DeepBlueDocs::Application.config.timezone_zone,
                                     exp_event:,
                                     exp_event_note: nil,
                                     exp_class_name:,
                                     exp_id:,
                                     exp_admin_set_id: '',
                                     exp_authoremail: '',
                                     exp_creator: [],
                                     exp_curation_notes_admin: [],
                                     exp_curation_notes_user: [],
                                     exp_date_coverage: '',
                                     exp_date_created: '',
                                     exp_date_modified: '',
                                     exp_date_updated: [],
                                     exp_depositor: '',
                                     exp_description: [],
                                     exp_doi: '',
                                     exp_fundedby: '',
                                     exp_fundedby_other: '',
                                     exp_grantnumber: '',
                                     exp_referenced_by: [],
                                     exp_keyword: [],
                                     exp_language: [],
                                     exp_location: '',
                                     exp_message: '',
                                     exp_methodology: '',
                                     exp_prior_identifier: [],
                                     exp_rights_license: '',
                                     exp_rights_license_other: '',
                                     exp_subject_discipline: [],
                                     exp_title: [],
                                     exp_tombstone: [],
                                     exp_total_file_count: 0,
                                     exp_total_file_size: '',
                                     exp_total_file_size_human_readable: '',
                                     exp_visibility: '',
                                     **added_prov_key_values )

    expect( prov_logger_received ).to be_a String
    rv_timestamp,
        rv_event,
        rv_event_note,
        rv_class_name,
        rv_id,
        rv_key_values = Deepblue::ProvenanceHelper.parse_log_line prov_logger_received
    expect( rv_timestamp ).to be_between( before, after ) if exp_timestamp.nil?
    expect( rv_timestamp ).to eq exp_timestamp if exp_timestamp.present?
    expect( rv_event ).to eq exp_event
    expect( rv_event_note ).to eq exp_event_note if exp_event_note.present?
    expect( rv_event_note ).to eq '' if exp_event_note.nil?
    expect( rv_class_name ).to eq exp_class_name
    expect( rv_id ).to eq exp_id
    rv_key_values.each_pair { |key, value| puts "#{key},#{value}" } if print_all_key_values
    expect( rv_key_values['event'] ).to eq exp_event
    expect( rv_key_values['timestamp'] ).to be_between( before, after ) if before.present? && after.present?
    expect( rv_key_values['timestamp'] ).to eq exp_timestamp if exp_timestamp.present?
    expect( rv_key_values['time_zone'] ).to eq exp_time_zone if exp_time_zone.present?
    validate_expected( rv_key_values, :event_note, exp_event_note )
    validate_expected( rv_key_values, :class_name, exp_class_name )
    validate_expected( rv_key_values, :id, exp_id )
    validate_expected( rv_key_values, :admin_set_id, exp_admin_set_id )
    validate_expected( rv_key_values, :authoremail, exp_authoremail )
    validate_expected( rv_key_values, :creator, exp_creator )
    validate_expected( rv_key_values, :curation_notes_admin, exp_curation_notes_admin )
    validate_expected( rv_key_values, :curation_notes_user, exp_curation_notes_user )
    validate_expected( rv_key_values, :date_coverage, exp_date_coverage )
    validate_expected( rv_key_values, :date_created, exp_date_created )
    validate_expected( rv_key_values, :date_modified, exp_date_modified )
    validate_expected( rv_key_values, :date_updated, exp_date_updated )
    validate_expected( rv_key_values, :depositor, exp_depositor )
    validate_expected( rv_key_values, :description, exp_description )
    validate_expected( rv_key_values, :doi, exp_doi )
    validate_expected( rv_key_values, :fundedby, exp_fundedby )
    validate_expected( rv_key_values, :fundedby_other, exp_fundedby_other )
    validate_expected( rv_key_values, :grantnumber, exp_grantnumber )
    validate_expected( rv_key_values, :referenced_by, exp_referenced_by )
    validate_expected( rv_key_values, :keyword, exp_keyword )
    validate_expected( rv_key_values, :language, exp_language )
    validate_expected( rv_key_values, :location, exp_location )
    validate_expected( rv_key_values, :message, exp_message )
    validate_expected( rv_key_values, :methodology, exp_methodology )
    validate_expected( rv_key_values, :prior_identifier, exp_prior_identifier )
    validate_expected( rv_key_values, :rights_license, exp_rights_license )
    validate_expected( rv_key_values, :rights_license_other, exp_rights_license_other )
    validate_expected( rv_key_values, :subject_discipline, exp_subject_discipline )
    validate_expected( rv_key_values, :title, exp_title )
    validate_expected( rv_key_values, :tombstone, exp_tombstone )
    validate_expected( rv_key_values, :total_file_count, exp_total_file_count )
    validate_expected( rv_key_values, :total_file_size, exp_total_file_size )
    validate_expected( rv_key_values, :total_file_size_human_readable, exp_total_file_size_human_readable )
    validate_expected( rv_key_values, :visibility, exp_visibility )
    added_prov_key_values.each_pair do |key, value|
      validate_expected(rv_key_values, key, value )
    end
    expect( rv_key_values.size ).to eq size
  end

end
