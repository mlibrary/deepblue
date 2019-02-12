# frozen_string_literal: true

RSpec.describe Deepblue::ProvenanceHelper, type: :helper do

  describe 'constants' do
    it do
      expect( Deepblue::JsonLoggerHelper::TIMESTAMP_FORMAT ).to eq '\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d'
      expect( Deepblue::JsonLoggerHelper::RE_TIMESTAMP_FORMAT.source ).to eq '^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$'
      expect( Deepblue::JsonLoggerHelper::RE_LOG_LINE.source ).to \
        eq '^(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d) ([^/]+)/([^/]*)/([^/]+)/([^/ ]*) (.*)$'
      expect( Deepblue::JsonLoggerHelper::PREFIX_UPDATE_ATTRIBUTE ).to eq 'UpdateAttribute_'
    end
  end

  describe '.echo_to_rails_logger' do
    subject { Deepblue::ProvenanceHelper.echo_to_rails_logger }
    it { expect( subject ).to eq true }
  end

  describe '.form_params_to_update_attribute_key_values' do
    let( :authoremail ) { 'authoremail@umich.edu' }
    let( :creator ) { 'Creator, A' }
    let( :current_user ) { 'user@umich.edu' }
    let( :date_created ) { '2018-02-28' }
    let( :depositor ) { authoremail }
    let( :description ) { 'The Description' }
    let( :id ) { '0123458678' }
    let( :methodology ) { 'The Methodology' }
    let( :methodology_new ) { 'The New Methodology' }
    let( :rights_license ) { 'The Rights License' }
    let( :subject_discipline ) { 'The Subject Discipline' }
    let( :title ) { 'The Title' }
    let( :visibility_private ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let( :visibility_public ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let( :curation_concern ) do
      DataSet.new( authoremail: authoremail,
                   title: [title],
                   creator: [creator],
                   date_created: date_created,
                   depositor: depositor,
                   description: [description],
                   methodology: methodology,
                   rights_license: rights_license,
                   subject_discipline: [subject_discipline],
                   visibility: visibility_public )
    end

    context 'No changes' do
      let( :form_params ) do
        { "title": [title, ""],
          "creator": [creator, ""],
          "authoremail": authoremail,
          "methodology": methodology,
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
          "date_coverage": "" }
      end
      let( :expected_attr_key_values ) { {} }

      it do
        attr_key_values = Deepblue::ProvenanceHelper.form_params_to_update_attribute_key_values( curation_concern: curation_concern,
                                                                                                 form_params: form_params )
        expect( attr_key_values ).to eq expected_attr_key_values
      end
    end

    context 'methodology updated' do
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
          "date_coverage": "" }
      end
      let( :expected_attr_key_values ) { { UpdateAttribute_methodology: { attribute: :methodology, old_value: methodology, new_value: methodology_new } } }

      it do
        attr_key_values = Deepblue::ProvenanceHelper.form_params_to_update_attribute_key_values( curation_concern: curation_concern,
                                                                                                 form_params: form_params )
        expect( attr_key_values ).to eq expected_attr_key_values
      end
    end

  end

  describe '.initialize_prov_key_values' do
    let( :event_note ) { 'the_event_note' }
    let( :user_email ) { 'user@email.com' }

    context 'parameters: user_email and event_note' do
      subject do
        lambda do |user_email, event_note|
          Deepblue::ProvenanceHelper.logger_initialize_key_values(user_email: user_email, event_note: event_note )
        end
      end

      let( :result_both ) { { user_email: user_email, event_note: event_note } }
      let( :result_no_event_note ) { { user_email: user_email } }

      it { expect( subject.call( user_email, event_note ) ).to eq result_both }
      it { expect( subject.call( user_email, '' ) ).to eq result_no_event_note }
      it { expect( subject.call( user_email, nil ) ).to eq result_no_event_note }
    end

    context 'parameters: user_email, event_note and added' do
      let( :added1 ) { 'one' }
      let( :added2 ) { 'two' }

      let( :result1 ) { { user_email: user_email, event_note: event_note, added1: added1 } }
      let( :result2 ) { { user_email: user_email, event_note: event_note, added1: added1, added2: added2 } }

      it 'returns a hash containing user_email, event_note, and added1' do
        expect( Deepblue::ProvenanceHelper.logger_initialize_key_values(user_email: user_email,
                                                                        event_note: event_note,
                                                                        added1: added1 ) ).to eq result1
      end

      it 'returns a hash containing user_email, event_note, added1, and added2' do
        expect( Deepblue::ProvenanceHelper.logger_initialize_key_values(user_email: user_email,
                                                                        event_note: event_note,
                                                                        added1: added1,
                                                                        added2: added2 ) ).to eq result2
      end
    end
  end

  describe '.msg_to_log' do
    let( :class_name ) { 'DataSet' }
    let( :event ) { 'the_event' }
    let( :event_note ) { 'the_event_note' }
    let( :blank_event_note ) { '' }
    let( :id ) { 'id1234' }
    let( :timestamp ) { Time.now.to_formatted_s(:db ) }

    context 'parms without added' do
      let( :key_values ) { { event: event,
                             event_note: event_note,
                             timestamp: timestamp,
                             class_name: class_name,
                             id: id } }
      let( :json ) { ActiveSupport::JSON.encode key_values }
      let( :result1 ) { "#{timestamp} #{event}/#{event_note}/#{class_name}/#{id} #{json}" }
      it do
        expect( Deepblue::ProvenanceHelper.msg_to_log( class_name: class_name,
                                                       event: event,
                                                       event_note: event_note,
                                                       id: id,
                                                       timestamp: timestamp ) ).to eq result1
      end
    end

    context 'parms, blank event_note, without added' do
      let( :key_values ) { { event: event, timestamp: timestamp, class_name: class_name, id: id } }
      let( :json ) { ActiveSupport::JSON.encode key_values }
      let( :result1 ) { "#{timestamp} #{event}//#{class_name}/#{id} #{json}" }
      it do
        expect( Deepblue::ProvenanceHelper.msg_to_log( class_name: class_name,
                                                       event: event,
                                                       event_note: blank_event_note,
                                                       id: id,
                                                       timestamp: timestamp ) ).to eq result1
      end
    end
  end

  describe '.log' do
    let( :added1 ) { 'one' }
    let( :added2 ) { 'two' }
    let( :class_name ) { 'DataSet' }
    let( :class_name_default ) { 'UnknownClass' }
    let( :event ) { 'the_event' }
    let( :event_default ) { 'unknown' }
    let( :event_note ) { 'the_event_note' }
    let( :event_note_default ) { '' }
    let( :blank_event_note ) { '' }
    let( :id ) { 'id1234' }
    let( :id_default ) { 'unknown_id' }
    let( :timestamp ) { Time.now.to_formatted_s(:db ) }

    context 'no parms' do
      it do
        prov_logger_received = nil
        allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
        before = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
        Deepblue::ProvenanceHelper.log
        after = Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now
        expect( prov_logger_received ).to be_a String
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line prov_logger_received
        expect( rv_timestamp ).to be_between( before, after )
        expect( rv_event ).to eq event_default
        expect( rv_event_note ).to eq event_note_default
        expect( rv_class_name ).to eq class_name_default
        expect( rv_id ).to eq id_default
        expect( rv_key_values['timestamp'] ).to be_between( before, after )
        expect( rv_key_values['event'] ).to eq event_default
        # expect( rv_key_values['event_note'] ).to eq event_note_default
        expect( rv_key_values['class_name'] ).to eq class_name_default
        expect( rv_key_values['id'] ).to eq id_default
        expect( rv_key_values.size ).to eq 4
      end
    end

    context 'parms specified, no added' do
      let( :timestamp ) { Deepblue::ProvenanceHelper.to_log_format_timestamp( 5.minutes.ago ) }
      it do
        prov_logger_received = nil
        allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
        Deepblue::ProvenanceHelper.log( class_name: class_name,
                                        event: event,
                                        event_note: event_note,
                                        id: id,
                                        timestamp: timestamp )
        expect( prov_logger_received ).to be_a String
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line prov_logger_received
        expect( rv_timestamp ).to eq timestamp
        expect( rv_event ).to eq event
        expect( rv_event_note ).to eq event_note
        expect( rv_class_name ).to eq class_name
        expect( rv_id ).to eq id
        expect( rv_key_values['timestamp'] ).to eq timestamp
        expect( rv_key_values['event'] ).to eq event
        expect( rv_key_values['event_note'] ).to eq event_note
        expect( rv_key_values['class_name'] ).to eq class_name
        expect( rv_key_values['id'] ).to eq id
        expect( rv_key_values.size ).to eq 5
      end
    end

    context 'parms specified and added' do
      let( :timestamp ) { Deepblue::ProvenanceHelper.to_log_format_timestamp( 5.minutes.ago ) }
      it do
        prov_logger_received = nil
        allow( PROV_LOGGER ).to receive( :info ) { |msg| prov_logger_received = msg }
        Deepblue::ProvenanceHelper.log( class_name: class_name,
                                        event: event,
                                        event_note: event_note,
                                        id: id,
                                        timestamp: timestamp,
                                        added1: added1,
                                        added2: added2 )
        expect( prov_logger_received ).to be_a String
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line prov_logger_received
        expect( rv_timestamp ).to eq timestamp
        expect( rv_event ).to eq event
        expect( rv_event_note ).to eq event_note
        expect( rv_class_name ).to eq class_name
        expect( rv_id ).to eq id
        expect( rv_key_values['timestamp'] ).to eq timestamp
        expect( rv_key_values['event'] ).to eq event
        expect( rv_key_values['event_note'] ).to eq event_note
        expect( rv_key_values['class_name'] ).to eq class_name
        expect( rv_key_values['id'] ).to eq id
        expect( rv_key_values['added1'] ).to eq added1
        expect( rv_key_values['added2'] ).to eq added2
        expect( rv_key_values.size ).to eq 7
      end
    end
  end

  describe '.log_raw' do
    let( :msg ) { 'The message.' }
    before do
      allow( PROV_LOGGER ).to receive( :info ).with( msg )
    end
    it do
      Deepblue::ProvenanceHelper.log_raw msg
    end
  end

  describe '.parse_log_line' do
    let( :added1 ) { 'one' }
    let( :added2 ) { 'two' }
    let( :class_name ) { 'DataSet' }
    let( :event ) { 'the_event' }
    let( :event_note ) { 'the_event_note' }
    let( :blank_event_note ) { '' }
    let( :id ) { 'id1234' }
    let( :timestamp ) { Time.now.to_formatted_s(:db ) }

    context 'bad input raises error' do
      it do
        expect { Deepblue::ProvenanceHelper.parse_log_line( '' ) }.to \
          raise_error( Deepblue::LogParseError, "parse of log line failed: ''" )
        expect { Deepblue::ProvenanceHelper.parse_log_line( nil ) }.to \
          raise_error( Deepblue::LogParseError, "parse of log line failed: ''" )
        expect { Deepblue::ProvenanceHelper.parse_log_line( 'Some non-formatted line' ) }.to \
          raise_error( Deepblue::LogParseError, "parse of log line failed: 'Some non-formatted line'" )
      end
    end

    context 'parms and added parms' do
      let( :before ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      let( :line ) { Deepblue::ProvenanceHelper.msg_to_log( class_name: class_name,
                                                            event: event,
                                                            event_note: event_note,
                                                            id: id,
                                                            timestamp: timestamp,
                                                            added1: added1,
                                                            added2: added2 ) }
      let( :after ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      it do
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line line
        expect( rv_timestamp ).to be_between( before, after )
        expect( rv_event ).to eq event
        expect( rv_event_note ).to eq event_note
        expect( rv_class_name ).to eq class_name
        expect( rv_id ).to eq id
        expect( rv_key_values['timestamp'] ).to be_between( before, after )
        expect( rv_key_values['event'] ).to eq event
        expect( rv_key_values['event_note'] ).to eq event_note
        expect( rv_key_values['class_name'] ).to eq class_name
        expect( rv_key_values['id'] ).to eq id
        expect( rv_key_values['added1'] ).to eq added1
        expect( rv_key_values['added2'] ).to eq added2
        expect( rv_key_values.size ).to eq 7
      end
    end

    context 'parms without added' do
      let( :before ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      let( :line ) { Deepblue::ProvenanceHelper.msg_to_log( class_name: class_name,
                                                            event: event,
                                                            event_note: event_note,
                                                            id: id,
                                                            timestamp: timestamp ) }
      let( :after ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      it do
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line line
        expect( rv_timestamp ).to be_between( before, after )
        expect( rv_event ).to eq event
        expect( rv_event_note ).to eq event_note
        expect( rv_class_name ).to eq class_name
        expect( rv_id ).to eq id
        expect( rv_key_values['timestamp'] ).to be_between( before, after )
        expect( rv_key_values['event'] ).to eq event
        expect( rv_key_values['event_note'] ).to eq event_note
        expect( rv_key_values['class_name'] ).to eq class_name
        expect( rv_key_values['id'] ).to eq id
        expect( rv_key_values.size ).to eq 5
      end
    end

    context 'parms without added and blank event note' do
      let( :before ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      let( :line ) { Deepblue::ProvenanceHelper.msg_to_log( class_name: class_name,
                                                            event: event,
                                                            event_note: blank_event_note,
                                                            id: id,
                                                            timestamp: timestamp ) }
      let( :after ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      it do
        rv_timestamp,
            rv_event,
            rv_event_note,
            rv_class_name,
            rv_id,
            rv_key_values = Deepblue::ProvenanceHelper.parse_log_line line
        expect( rv_timestamp ).to be_between( before, after )
        expect( rv_event ).to eq event
        expect( rv_event_note ).to eq blank_event_note
        expect( rv_class_name ).to eq class_name
        expect( rv_id ).to eq id
        expect( rv_key_values['timestamp'] ).to be_between( before, after )
        expect( rv_key_values['event'] ).to eq event
        # expect( rv_key_values['event_note'] ).to eq event_note
        expect( rv_key_values['class_name'] ).to eq class_name
        expect( rv_key_values['id'] ).to eq id
        expect( rv_key_values.size ).to eq 4
      end
    end
  end

  describe '.system_as_current_user' do
    subject { Deepblue::ProvenanceHelper.system_as_current_user }
    it { expect( subject ).to eq 'Deepblue' }
  end

  describe '.timestamp_now' do
    context 'is formatted correctly' do
      it do
        expect( Deepblue::ProvenanceHelper.timestamp_now ).to match '^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$'
      end
    end
    context 'is now' do
      let( :before ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      let( :timestamp_now ) { Deepblue::ProvenanceHelper.timestamp_now }
      let( :after ) { Deepblue::ProvenanceHelper.to_log_format_timestamp Time.now }
      it do
        expect( timestamp_now ).to be_between( before, after )
      end
    end
  end

  describe '.to_log_format_timestamp' do
    let( :time_now ) { Time.now }
    let( :timestamp_now ) { time_now.to_formatted_s( :db ) }
    let( :timestamp_re ) { '^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d$' }
    context 'for correctly formatted string' do
      it do
        expect( Deepblue::ProvenanceHelper.to_log_format_timestamp( timestamp_now ) ).to match timestamp_re
      end
    end
    context 'for correctly Time' do
      it do
        expect( Deepblue::ProvenanceHelper.to_log_format_timestamp( time_now ) ).to match timestamp_re
      end
    end
    context 'for correctly different format string' do
      it do
        expect( Deepblue::ProvenanceHelper.to_log_format_timestamp( time_now.to_s ) ).to match timestamp_re
      end
    end
  end

  describe '.update_attribute_key_values' do
    let( :authoremail ) { 'authoremail@umich.edu' }
    let( :creator ) { [ 'Creator, A' ] }
    let( :current_user ) { 'user@umich.edu' }
    let( :date_created ) { '2018-02-28' }
    let( :depositor ) { authoremail }
    let( :description ) { [ 'The Description' ] }
    let( :id ) { '0123458678' }
    let( :methodology_new ) { 'The New Methodology' }
    let( :methodology_old ) { 'The Old Methodology' }
    let( :rights_license ) { 'The Rights License' }
    let( :title ) { [ 'The Title' ] }
    let( :subject_discipline ) { 'The Subject Discipline' }
    let( :visibility_private ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let( :visibility_public ) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let( :curation_concern ) do
      DataSet.new( authoremail: authoremail,
                   title: title,
                   creator: creator,
                   date_created: date_created,
                   depositor: depositor,
                   description: description,
                   methodology: methodology_new,
                   rights_license: rights_license,
                   subject_discipline: [subject_discipline],
                   visibility: visibility_public )
    end
    let( :update_attr_key_values ) { { UpdateAttribute_methodology: { attribute: :methodology, old_value: methodology_old, new_value: 'some value from form' } } }
    it do
      updated = Deepblue::ProvenanceHelper.update_attribute_key_values( curation_concern: curation_concern,
                                                                        update_attr_key_values: update_attr_key_values )
      # puts ActiveSupport::JSON.encode updated
      # updated = updated[:update_attr_key_values]
      expect( updated.size ).to be 1
      expect( updated.key?(:UpdateAttribute_methodology) ).to be true
      expect( updated[:UpdateAttribute_methodology][:attribute] ).to eq :methodology
      expect( updated[:UpdateAttribute_methodology][:old_value] ).to eq methodology_old
      expect( updated[:UpdateAttribute_methodology][:new_value] ).to eq methodology_new
    end
  end

end
