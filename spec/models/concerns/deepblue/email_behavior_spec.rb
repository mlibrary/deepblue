require 'rails_helper'

class EmailBehaviorCCMock
  include ::Deepblue::EmailBehavior

  attr_accessor :date_modified, :id

  def initialize(id, attributes: {})
    @id = id
    @attributes = attributes.dup
  end

  def [](key)
    @attributes[key]
  end

  def []=(key, value)
    @attributes[key] = value
  end

  def event_attributes_cache_write( event:, id:, attributes: DateTime.now, behavior: nil ); end

end

RSpec.describe ::Deepblue::EmailBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.email_behavior_debug_verbose ).to eq debug_verbose }
  end

  before do
    allow(::Deepblue::LoggingHelper ).to receive(:timestamp_now).and_return 'TIMESTAMP_NOW'
  end

  let(:id)         { 'an_id' }
  let(:mock_attrs) { { :date_created => 'date_created_value', 'test_key' => 'test_value'} }
  let(:cc_mock)    { EmailBehaviorCCMock.new(id, attributes: mock_attrs) }
  let(:user)       { create(:user) }
  let(:event)      { 'EVENT' }
  let(:event_publish) { ::Deepblue::AbstractEventBehavior::EVENT_PUBLISH }
  let(:event_note) { 'event note' }
  let(:use_blank_key_values)    { ::Deepblue::AbstractEventBehavior::USE_BLANK_KEY_VALUES }
  let(:ignore_the_blank_key_values) { ::Deepblue::AbstractEventBehavior::IGNORE_BLANK_KEY_VALUES }
  let(:notification_email_to)   { 'notification@email.to' }
  let(:notification_email_from) { 'notification@email.from' }

  it { expect(cc_mock.attributes_all_for_email).to eq [] }
  it { expect(cc_mock.attributes_brief_for_email).to eq [] }
  it { expect(cc_mock.attributes_standard_for_email).to eq [] }
  it { expect(cc_mock.attributes_for_email_event_create_rds).to eq [[], use_blank_key_values] }
  it { expect(cc_mock.attributes_for_email_event_create_user).to eq [] }
  it { expect(cc_mock.attributes_for_email_event_destroy_rds).to eq [[], use_blank_key_values] }
  it { expect(cc_mock.attributes_for_email_event_destroy_user).to eq [[], use_blank_key_values] }
  it { expect(cc_mock.attributes_for_email_event_globus_rds).to eq [[], ignore_the_blank_key_values] }
  it { expect(cc_mock.attributes_for_email_event_publish_rds).to eq [[], use_blank_key_values] }
  it { expect(cc_mock.attributes_for_email_event_unpublish_rds).to eq [[], use_blank_key_values] }

  it { expect(cc_mock.for_email_object).to eq cc_mock }
  it { expect(cc_mock.for_email_class).to eq cc_mock.class }
  it { expect(cc_mock.for_email_id).to eq id }
  it { expect(cc_mock.for_email_ignore_empty_attributes).to eq true }
  it { expect(cc_mock.for_email_label('key')).to eq "key: " }
  it { expect(cc_mock.for_email_route).to eq "route to #{id}" }
  it { expect(cc_mock.for_email_subject(subject_rest: 'the rest')).to eq "DBD: the rest" }

  describe '#for_email_user' do

    it { expect(cc_mock.for_email_user(nil)).to eq '' }
    it { expect(cc_mock.for_email_user('is_a_string')).to eq 'is_a_string' }
    it { expect(cc_mock.for_email_user(user)).to eq user.email }

  end

  describe '#for_email_value' do
    let(:url)  { 'http:://anchor.com' }
    let(:url_anchored) { ::Deepblue::EmailHelper.to_anchor( url ) }
    let(:arr0) { [] }
    let(:arr1) { ['value1', 'value2'] }
    let(:html) { ::Deepblue::EmailHelper::TEXT_HTML }
    it { expect(cc_mock.for_email_value('key', nil)).to eq '' }
    it { expect(cc_mock.for_email_value('key', [])).to eq '' }
    it { expect(cc_mock.for_email_value('key', 'value')).to eq 'value' }
    it { expect(cc_mock.for_email_value('key', nil, content_type: html )).to eq '' }
    it { expect(cc_mock.for_email_value('key', 'value', content_type: html )).to eq 'value' }
    it { expect(cc_mock.for_email_value('key', url, content_type: html )).to eq url_anchored }
    it { expect(cc_mock.for_email_value('key', arr0)).to eq '' }
    it { expect(cc_mock.for_email_value('key', arr1)).to eq arr1.join('; ') }
    it { expect(cc_mock.for_email_value('key', arr1, content_type: html )).to eq arr1.join('; ') }
    it { expect(cc_mock.for_email_value('title', arr0)).to eq '' }
    it { expect(cc_mock.for_email_value('title', arr1)).to eq arr1.join(' ') }
    it { expect(cc_mock.for_email_value('title', arr1, content_type: html)).to eq arr1.join(' ') }
  end

  describe '#for_email_value_sep' do
    it { expect(cc_mock.for_email_value_sep(key: 'title')).to eq ' ' }
    it { expect(cc_mock.for_email_value_sep(key: 'other')).to eq '; ' }
  end

  describe '#email_address_workflow' do
    before do
      allow(::Deepblue::EmailHelper).to receive(:notification_email_to).and_return notification_email_to
      allow(::Deepblue::EmailHelper).to receive(:notification_email_from).and_return notification_email_from
    end
    it { expect(cc_mock.email_address_workflow).to eq [notification_email_to,
                                                       'RDS-workflow-event',
                                                       notification_email_from] }

  end

  describe '#email_attribute_values_for_snapshot' do

    context 'all parameters' do
      let(:added_key_email_key_values) { { key1: 'value1', key2: 'value2' } }
      let(:attributes) { [:id, :location, :route, :date_created] }
      let(:to_note) { 'to note value' }
      let(:expected_attribute_values) { { user_email: user.email,
                                          event_note: event_note,
                                          to_note: to_note,
                                          key1: 'value1',
                                          key2: 'value2',
                                          id: id,
                                          location: cc_mock.for_email_route,
                                          route: cc_mock.for_email_route,
                                          date_created: 'date_created_value' } }

      it { expect(cc_mock.email_attribute_values_for_snapshot(attributes: attributes,
                                                              current_user: user,
                                                              event: event,
                                                              event_note: event_note,
                                                              to_note: to_note,
                                                              ignore_blank_key_values: false,
                                                              **added_key_email_key_values)).to eq expected_attribute_values}

    end

    context 'minimal parameters' do
      let(:added_key_email_key_values) { { } }
      let(:attributes) { [] }
      let(:to_note) { nil }
      let(:expected_attribute_values) { { user_email: user.email, event_note: event_note } }

      it { expect(cc_mock.email_attribute_values_for_snapshot(attributes: attributes,
                                                              current_user: user,
                                                              event: event,
                                                              event_note: event_note,
                                                              to_note: to_note,
                                                              ignore_blank_key_values: false,
                                                              **added_key_email_key_values)).to eq expected_attribute_values}


    end

  end

  describe '#email_event_publish_rds' do
    let(:attributes) { [:id, :location] }
    let(:from_addr)  { notification_email_from }
    let(:subject)    { 'The Subject Line' }
    let(:to_addr)    { notification_email_to }
    let(:to_note)    { 'RDS-workflow-event' }
    let(:content_type) { ::Deepblue::EmailHelper::TEXT_HTML }
    let(:curation_concern_type) { 'the cc type' }
    let(:message) { 'the message' }
    let(:email_key_values) { {:user_email=>user.email,
                              :event_note=>event_note,
                              :to_note=>to_note,
                              :id=>id } }
    let(:body) { [ message,
                   "<pre>",
                   "user_email: #{user.email}",
                   "event_note: #{event_note}",
                   "to_note: #{to_note}",
                   "</pre>\n" ].join("\n") }

    before do
      allow(::Deepblue::EmailHelper).to receive(:t).and_return subject
      allow(::Deepblue::EmailHelper).to receive(:notification_email_to).and_return notification_email_to
      allow(::Deepblue::EmailHelper).to receive(:notification_email_from).and_return notification_email_from
      allow(::Deepblue::EmailHelper).to receive(:curation_concern_type).with(curation_concern: cc_mock).and_return curation_concern_type

      expect(::Deepblue::EmailHelper).to receive(:send_email).with(to: to_addr,
                                                                   from: from_addr,
                                                                   subject: subject,
                                                                   body: body,
                                                                   content_type: content_type).and_return true
      expect(::Deepblue::EmailHelper).to receive(:log).with(class_name: cc_mock.for_email_class.name,
                                                            event: event_publish,
                                                            event_note: event_note,
                                                            id: id,
                                                            to: to_addr,
                                                            cc: nil,
                                                            bcc: nil,
                                                            from: from_addr,
                                                            subject: subject,
                                                            message: message,
                                                            body: body,
                                                            email_sent: true,
                                                            **email_key_values)
      expect(cc_mock).to_not receive(:email_event_notification_failed)
    end

    it { expect(cc_mock.email_event_publish_rds(current_user: user,
                                                event_note: event_note,
                                                message: 'the message')).to eq nil }

  end

  describe '#email_event_publish_user' do
    let(:cc_contact_email) { 'contact_email@sample.com' }
    let(:cc_depositor)     { 'The Depositor' }
    let(:cc_title)         { "The Title" }
    let(:cc_type)          { 'work' }
    let(:cc_url)           { "http://some.url.com" }

    let(:template_key) { "hyrax.email.notify_user_#{cc_type}_published_html" }
    let(:body1) { "body1" }
    let(:body2) { "body2" }

    before do
      allow( ::Deepblue::EmailHelper ).to receive(:cc_title).with(curation_concern: cc_mock).and_return cc_title
      allow( ::Deepblue::EmailHelper ).to receive(:curation_concern_type).with(curation_concern: cc_mock).and_return cc_type
      allow( ::Deepblue::EmailHelper ).to receive(:curation_concern_url).with(curation_concern: cc_mock).and_return cc_url
      allow( ::Deepblue::EmailHelper ).to receive(:cc_depositor).with(curation_concern: cc_mock).and_return cc_depositor
      allow( ::Deepblue::EmailHelper ).to receive(:cc_contact_email).with(curation_concern: cc_mock).and_return cc_contact_email
      allow( ::Deepblue::EmailHelper ).to receive(:t).with( "hyrax.email.subject.work_published" ).and_call_original
      expect( ::Deepblue::JiraHelper ).to receive(:jira_add_comment).with( curation_concern: cc_mock,
                                                                           event: event_publish,
                                                                           comment: body1 )
      expect( ::Deepblue::EmailHelper ).to receive(:t!).with( template_key,
                                                           title: cc_title,
                                                           url: cc_url,
                                                           depositor: cc_depositor,
                                                           contact_us_at: ::Deepblue::EmailHelper.contact_us_at ).and_return body1
      expect( cc_mock ).to receive( :email_notification ).with( to: cc_depositor,
                          from: ::Deepblue::EmailHelper.notification_email_from,
                          content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                          subject: ::Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_published" ),
                          body: body1,
                          current_user: user,
                          event: event_publish,
                          event_note: event_note,
                          id: cc_mock.for_email_id )
      expect( ::Deepblue::EmailHelper ).to receive(:t!).with( template_key,
                                                           title: cc_title,
                                                           url: cc_url,
                                                           depositor: cc_contact_email,
                                                           contact_us_at: ::Deepblue::EmailHelper.contact_us_at ).and_return body2
      expect( cc_mock ).to receive( :email_notification ).with( to: cc_contact_email,
                                                                from: ::Deepblue::EmailHelper.notification_email_from,
                                                                content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                                                                subject: ::Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_published" ),
                                                                body: body2,
                                                                current_user: user,
                                                                event: event_publish,
                                                                event_note: event_note,
                                                                id: cc_mock.for_email_id )
    end

    it { expect(cc_mock.email_event_publish_user(current_user: user,
                                                 event_note: event_note,
                                                 message: 'the message')).to eq nil }

  end

  describe '#email_notification' do
    let(:from_addr)  { 'from@email.com'}
    let(:subject)    { 'The Subject Line' }
    let(:to_addr)    { 'to@email.com'}
    let(:content_type) { nil }

    context 'simple notification' do
      let(:message) { 'the message' }
      let(:expected_rv) { nil }
      let(:email_key_values) { { :key1=>"value 1", :key2=>"value 2" } }
      let(:body) { "The Body of the Email." }

      before do
        expect(::Deepblue::EmailHelper).to receive(:send_email).with(to: to_addr,
                                                                     from: from_addr,
                                                                     cc: nil,
                                                                     bcc: nil,
                                                                     subject: subject,
                                                                     body: body,
                                                                     content_type: content_type).and_return true
        expect(::Deepblue::EmailHelper).to receive(:log).with(class_name: cc_mock.for_email_class.name,
                                                              current_user: user,
                                                              event: event,
                                                              event_note: event_note,
                                                              id: id,
                                                              to: to_addr,
                                                              cc: nil,
                                                              bcc: nil,
                                                              from: from_addr,
                                                              subject: subject,
                                                              message: message,
                                                              body: body,
                                                              email_sent: true,
                                                              **email_key_values)
        expect(cc_mock).to_not receive(:email_event_notification_failed)
      end
      it { expect( cc_mock.email_notification(to: to_addr,
                                              from: from_addr,
                                              subject: subject,
                                              current_user: user,
                                              event: event,
                                              event_note: event_note,
                                              message: message,
                                              id: id,
                                              body: body,
                                              email_key_values: email_key_values)).to eq expected_rv }
    end

  end

  describe '#email_event_notification' do
    let(:attributes) { [:id, :location] }
    let(:from_addr)  { 'from@email.com'}
    let(:subject)    { 'The Subject Line' }
    let(:to_addr)    { 'to@email.com'}
    let(:to_note)    { 'The to note.' }
    let(:content_type) { nil }

    context 'simple notification' do
      let(:message) { 'the message' }
      let(:expected_rv) { nil }
      let(:email_key_values) { {:user_email=>user.email,
                                :event_note=>event_note,
                                :to_note=>to_note,
                                :id=>id,
                                :location=>"route to #{id}"} }
      let(:body) { [ message,
                     "user_email: #{user.email}",
                     "event_note: #{event_note}",
                     "to_note: #{to_note}",
                     "id: an_id",
                     "location: route to #{id}\n" ].join("\n") }

      before do
        expect(::Deepblue::EmailHelper).to receive(:send_email).with(to: to_addr,
                                                                     from: from_addr,
                                                                     subject: subject,
                                                                     body: body,
                                                                     content_type: content_type).and_return true
        expect(::Deepblue::EmailHelper).to receive(:log).with(class_name: cc_mock.for_email_class.name,
                                                              event: event,
                                                              event_note: event_note,
                                                              id: id,
                                                              to: to_addr,
                                                              cc: nil,
                                                              bcc: nil,
                                                              from: from_addr,
                                                              subject: subject,
                                                              message: message,
                                                              body: body,
                                                              email_sent: true,
                                                              **email_key_values)
        expect(cc_mock).to_not receive(:email_event_notification_failed)
      end

      it { expect( cc_mock.email_event_notification( to: to_addr,
                                                     to_note: to_note,
                                                     from: from_addr,
                                                     subject: subject,
                                                     attributes: attributes,
                                                     current_user: user,
                                                     event: event,
                                                     event_note: event_note,
                                                     message: message,
                                                     id: id,
                                                     ignore_blank_key_values: false )).to eq expected_rv }
    end

    context 'simple notification and return email parameters' do
      let(:message) { 'the message' }
      let(:email_key_values) { {:user_email=>user.email,
                                :event_note=>event_note,
                                :to_note=>to_note,
                                :id=>id,
                                :location=>"route to #{id}"} }
      let(:body) { [ message,
                    "user_email: #{user.email}",
                    "event_note: #{event_note}",
                    "to_note: #{to_note}",
                    "id: an_id",
                    "location: route to #{id}\n" ].join("\n") }
      let(:expected_rv) {  {:bcc => nil,
                            :body => body,
                            :cc => nil,
                            :current_user => user,
                            :email_key_values => email_key_values,
                            :event => event,
                            :event_note => event_note,
                            :from => from_addr,
                            :id => id,
                            :message => message,
                            :subject => subject,
                            :to => to_addr,
                            :to_note=> to_note } }

      before do
        expect(::Deepblue::EmailHelper).to receive(:send_email).with(to: to_addr,
                                                         from: from_addr,
                                                         subject: subject,
                                                         body: body,
                                                         content_type: content_type).and_return true
        expect(::Deepblue::EmailHelper).to receive(:log).with(class_name: cc_mock.for_email_class.name,
                                                              event: event,
                                                              event_note: event_note,
                                                              id: id,
                                                              to: to_addr,
                                                              to_note: to_note,
                                                              cc: nil,
                                                              bcc: nil,
                                                              from: from_addr,
                                                              subject: subject,
                                                              message: message,
                                                              body: body,
                                                              email_sent: true,
                                                              **email_key_values)
        expect(cc_mock).to_not receive(:email_event_notification_failed)
      end

      it { expect( cc_mock.email_event_notification( to: to_addr,
                                                     to_note: to_note,
                                                     from: from_addr,
                                                     subject: subject,
                                                     attributes: attributes,
                                                     current_user: user,
                                                     event: event,
                                                     event_note: event_note,
                                                     message: message,
                                                     id: id,
                                                     ignore_blank_key_values: false,
                                                     return_email_parameters: true )).to eq expected_rv }
    end

  end

  it { expect(cc_mock.map_email_attributes_override!( event: nil,
                                                      attribute: nil,
                                                      ignore_blank_key_values: nil,
                                                      email_key_values: nil)).to eq false }

  describe '#map_email_attributes!' do

    context 'with attributes' do
      let(:attributes)       { [:id, :location, :route, :date_created, 'missing', 'test_key'] }
      let(:email_key_values) { { key1: 'value1', key2: 'value2' } }

      context 'and not ignore blank values' do
        let(:ignore_blank_key_values) { false }
        let(:expected_email_key_values)  { { key1: 'value1',
                                             key2: 'value2',
                                             key2: 'value2',
                                             id: id,
                                             location: cc_mock.for_email_route,
                                             route: cc_mock.for_email_route,
                                             date_created: 'date_created_value',
                                             'missing' => '',
                                             'test_key' => 'test_value' } }
        it { expect(cc_mock.map_email_attributes!(event: event,
                                                  attributes: attributes,
                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                  **email_key_values  )).to eq expected_email_key_values }
      end

      context 'and ignore blank values' do
        let(:ignore_blank_key_values) { true }
        let(:expected_email_key_values)  { { key1: 'value1',
                                             key2: 'value2',
                                             id: id,
                                             location: cc_mock.for_email_route,
                                             route: cc_mock.for_email_route,
                                             date_created: 'date_created_value',
                                             'test_key' => 'test_value' } }
        it { expect(cc_mock.map_email_attributes!(event: event,
                                                  attributes: attributes,
                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                  **email_key_values  )).to eq expected_email_key_values }
      end

    end

    context 'without attributes' do
      let(:ignore_blank_key_values) { false }
      let(:empty_attributes)        { [] }
      let(:expected_email_key_values)  { { } }
      it { expect(cc_mock.map_email_attributes!(event: event,
                                                attributes: empty_attributes,
                                                ignore_blank_key_values: ignore_blank_key_values )).to eq expected_email_key_values }
    end

  end


end
