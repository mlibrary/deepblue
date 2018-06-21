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
      date_coverage
      date_created
      date_modified
      date_updated
      depositor
      description
      doi
      fundedby
      grantnumber
      isReferencedBy
      keyword
      language
      location
      methodology
      rights_license
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

    it 'has breif metadata elements defined' do
      expect( subject.attributes_brief_for_provenance ).to eq metadata_keys_brief
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
    let( :prov_event ) { Deepblue::AbstractEventBehavior::EVENT_TOMBSTONE }
    let( :prov_class_name ) { 'DataSet' }
    let( :prov_id ) { id }
    let( :prov_depositor ) { "TOMBSTONE-#{depositor}" }
    let( :prov_visibility ) { visibility_private }
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
      expect( prov_logger_received ).to be_a String
      rv_timestamp,
          rv_event,
          rv_event_note,
          rv_class_name,
          rv_id,
          rv_key_values = Deepblue::ProvenanceHelper.parse_log_line prov_logger_received
      expect( rv_timestamp ).to be_between( before, after )
      expect( rv_event ).to eq prov_event
      expect( rv_event_note ).to eq ''
      expect( rv_class_name ).to eq prov_class_name
      expect( rv_id ).to eq prov_id
      # rv_key_values.each_pair { |key,value| puts "#{key},#{value}" }
      expect( rv_key_values['event'] ).to eq prov_event
      expect( rv_key_values['timestamp'] ).to be_between( before, after )
      # expect( rv_key_values['event_note'] ).to eq event_note_default
      expect( rv_key_values['class_name'] ).to eq prov_class_name
      expect( rv_key_values['id'] ).to eq prov_id
      expect( rv_key_values['epitaph'] ).to eq epitaph
      expect( rv_key_values['depositor'] ).to eq prov_depositor
      expect( rv_key_values['depositor_at_tombstone'] ).to eq depositor_at_tombstone
      expect( rv_key_values['visibility_at_tombstone'] ).to eq visibility_at_tombstone
      expect( rv_key_values['admin_set_id'] ).to eq ''
      expect( rv_key_values['authoremail'] ).to eq authoremail
      expect( rv_key_values['creator'] ).to eq [creator]
      expect( rv_key_values['date_coverage'] ).to eq ''
      expect( rv_key_values['date_created'] ).to eq "2" # TODO: this is wrong -- find out why
      expect( rv_key_values['date_modified'] ).to eq ''
      expect( rv_key_values['date_updated'] ).to eq []
      expect( rv_key_values['description'] ).to eq [description]
      expect( rv_key_values['doi'] ).to eq ''
      expect( rv_key_values['fundedby'] ).to eq ''
      expect( rv_key_values['grantnumber'] ).to eq ''
      expect( rv_key_values['isReferencedBy'] ).to eq []
      expect( rv_key_values['keyword'] ).to eq []
      expect( rv_key_values['language'] ).to eq []
      expect( rv_key_values['location'] ).to eq "/concern/data_sets/#{id}"
      expect( rv_key_values['methodology'] ).to eq methodology
      expect( rv_key_values['rights_license'] ).to eq rights_license
      expect( rv_key_values['subject_discipline'] ).to eq []
      expect( rv_key_values['title'] ).to eq [title]
      expect( rv_key_values['tombstone'] ).to eq [epitaph]
      expect( rv_key_values['total_file_count'] ).to eq 0
      expect( rv_key_values['total_file_size'] ).to eq ''
      # expect( rv_key_values['total_file_size_human_readable'] ).to eq nil
      expect( rv_key_values['visibility'] ).to eq prov_visibility
      expect( rv_key_values.size ).to eq 33
    end

  end

end
