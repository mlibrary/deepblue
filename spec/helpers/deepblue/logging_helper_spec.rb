# frozen_string_literal: true

RSpec.describe Deepblue::LoggingHelper, type: :helper do

  describe '.bold_debug' do
    let( :arrow_line ) { ">>>>>>>>>>" }
    let( :msg ) { 'The message.' }

    context 'with msg' do
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::LoggingHelper.bold_debug( msg )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 2 ).times
        expect( Rails.logger ).to have_received( :debug ).with( msg )
        expect( Rails.logger ).to have_received( :debug ).exactly( 3 ).times
      end
    end

    context 'with msg and lines: 2' do
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::LoggingHelper.bold_debug( msg, lines: 2 )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
        expect( Rails.logger ).to have_received( :debug ).with( msg )
        expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
      end
    end

    context 'with msg as array' do
      let( :msg_line_1 ) { "line 1" }
      let( :msg_line_2 ) { "line 2" }
      let( :msg_array ) { [ msg_line_1, msg_line_2 ] }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::LoggingHelper.bold_debug( msg_array )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 2 ).times
        expect( Rails.logger ).to have_received( :debug ).with( msg_line_1 )
        expect( Rails.logger ).to have_received( :debug ).with( msg_line_1 )
        expect( Rails.logger ).to have_received( :debug ).exactly( 4 ).times
      end
    end

    context 'with msg as hash' do
      let( :msg_key1 ) { :key1 }
      let( :msg_key2 ) { :key2 }
      let( :msg_value_1 ) { "value 1" }
      let( :msg_value_2 ) { "value 2" }
      let( :msg_hash ) { [ msg_key1 => msg_value_1, msg_key2 => msg_value_2 ] }
      before do
        allow( Rails.logger ).to receive( :debug ).with( any_args )
      end
      it do
        Deepblue::LoggingHelper.bold_debug( msg_hash )
        expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 2 ).times
        expect( Rails.logger ).to have_received( :debug ).with( "#{msg_key1}: #{msg_value_1}" )
        expect( Rails.logger ).to have_received( :debug ).with( "#{msg_key2}: #{msg_value_2}" )
        expect( Rails.logger ).to have_received( :debug ).exactly( 4 ).times
      end
    end

    # context 'with block msg' do
    #   let( :block_msg ) { 'The block message.' }
    #   before do
    #     allow( Rails.logger ).to receive( :debug ).with( any_args )
    #   end
    #   it do
    #     Deepblue::LoggingHelper.bold_debug( lines: 2 ) { block_msg }
    #     expect( Rails.logger ).to have_received( :debug ).with( arrow_line ).exactly( 4 ).times
    #     expect( Rails.logger ).to have_received( :debug ).with( block_msg )
    #     expect( Rails.logger ).to have_received( :debug ).exactly( 5 ).times
    #   end
    # end
  end

  describe '.initialize_key_values' do
    let( :event_note ) { 'the_event_note' }
    let( :user_email ) { 'user@email.com' }

    context 'parameters: user_email and event_note' do
      subject do
        lambda do |user_email, event_note|
          Deepblue::LoggingHelper.initialize_key_values( user_email: user_email, event_note: event_note )
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
        expect( Deepblue::LoggingHelper.initialize_key_values( user_email: user_email,
                                                               event_note: event_note,
                                                               added1: added1 ) ).to eq result1
      end

      it 'returns a hash containing user_email, event_note, added1, and added2' do
        expect( Deepblue::LoggingHelper.initialize_key_values( user_email: user_email,
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
    let( :time_zone ) { DateTime.now.zone }

    context 'parms without added' do
      let( :key_values ) { { event: event,
                             event_note: event_note,
                             timestamp: timestamp,
                             time_zone: time_zone,
                             class_name: class_name,
                             id: id } }
      let( :json ) { ActiveSupport::JSON.encode key_values }
      let( :result1 ) { "#{timestamp} #{event}/#{event_note}/#{class_name}/#{id} #{json}" }
      it do
        expect( Deepblue::LoggingHelper.msg_to_log( class_name: class_name,
                                                    event: event,
                                                    event_note: event_note,
                                                    id: id,
                                                    timestamp: timestamp,
                                                    time_zone: time_zone ) ).to eq result1
      end
    end

    context 'parms, blank event_note, without added' do
      let( :key_values ) { { event: event, timestamp: timestamp, time_zone: time_zone, class_name: class_name, id: id } }
      let( :json ) { ActiveSupport::JSON.encode key_values }
      let( :result1 ) { "#{timestamp} #{event}//#{class_name}/#{id} #{json}" }
      it do
        expect( Deepblue::LoggingHelper.msg_to_log( class_name: class_name,
                                                    event: event,
                                                    event_note: blank_event_note,
                                                    id: id,
                                                    timestamp: timestamp,
                                                    time_zone: time_zone ) ).to eq result1
      end
    end

  end

  describe '.system_as_current_user' do
    subject { Deepblue::LoggingHelper.system_as_current_user }
    it { expect( subject ).to eq 'Deepblue' }
  end

end
