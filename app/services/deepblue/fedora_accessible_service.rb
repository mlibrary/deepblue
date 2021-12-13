# frozen_string_literal: true

module Deepblue

  class FedoraAccessibleService

    mattr_accessor :fedora_accessible_service_debug_verbose, default: false

    def self.email_fedora_not_accessible( targets: )
      subject = "DBD: Fedora not accessible on #{hostname}"
      body =<<-END_BODY
#{subject}<br/>
END_BODY
      targets = targets.uniq
      targets.each do |email|
        ::Deepblue::JobTaskHelper.send_email( email_target: email,
                                              content_type: 'text/html',
                                              task_name: 'FedoraAccessibleJob',
                                              subject: subject,
                                              body: body,
                                              event: 'Fedora Not Accessible',
                                              event_note: '' )
      end
    end

    def self.fedora_accessible?
      # this tests for fedora, as versus PersistHelper.all.first.id
      ActiveFedora::Base.all.first.id
      # ActiveFedora::Base.where( id: Rails.configuration.default_admin_set_id )
      return true
    rescue RSolr::Error::ConnectionRefused
      false
    rescue Faraday::ConnectionFailed
      false
    rescue
      false
    end

    def self.hostname
      ::DeepBlueDocs::Application.config.hostname
    end

    def self.solr_accessible?
      # this tests for solr, as versus PersistHelper.all.count
      ActiveFedora::Base.all.count
    rescue RSolr::Error::ConnectionRefused
      false
    rescue
      false
    end

  end

end
