# frozen_string_literal: true

module Deepblue

  class FedoraAccessibleService

    mattr_accessor :fedora_accessible_service_debug_verbose, default: false

    def self.email_fedora_not_accessible( targets:, subject: nil, note: nil )
      subject ||= "DBD: Fedora not accessible on #{hostname}"
      note ||= ""
      body =<<-END_BODY
#{subject}<br/>
#{note}
END_BODY

      targets = targets.uniq
      targets.each do |email|
        ::Deepblue::JobTaskHelper.send_email( email_target: email,
                                              content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                                              task_name: 'FedoraNotAccessible',
                                              subject: subject,
                                              body: body,
                                              event: 'Fedora Not Accessible',
                                              event_note: '' )
      end
    end

    def self.fedora_accessible?
      # this tests for fedora, as versus PersistHelper.all.first.id
      # ActiveFedora::Base.all.first.id
      content_doc_collection_id_exists_in_fedora?
      # ::PersistHelper.where( id: Rails.configuration.default_admin_set_id )
      return true
    rescue RSolr::Error::ConnectionRefused
      false
    rescue Faraday::ConnectionFailed
      false
    rescue
      false
    end

    def self.hostname
      Rails.configuration.hostname
    end

    def self.solr_accessible?
      # this tests for solr, as versus PersistHelper.all.count
      ActiveFedora::Base.all.count
    rescue RSolr::Error::ConnectionRefused
      false
    rescue
      false
    end

    # Queries Fedora to figure out if there are versions for the resource.
    def content_doc_collection_id_exists_in_fedora?
      id = ::Deepblue::WorkViewContentService.content_documentation_collection_id
      uri = ActiveFedora::Base.id_to_uri(id)
      rv = ActiveFedora.fedora.connection.head(uri)
      rv.present?
    rescue Ldp::NotFound
      false
    end

  end

end
