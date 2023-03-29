# frozen_string_literal: true

module Deepblue

  module IngestBehavior

    mattr_accessor :ingest_behavior_debug_verbose, default: Rails.configuration.ingest_behavior_debug_verbose

    def ingest_attach( called_from: nil, parent_id: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "called_from=#{called_from}",
                                             "parent_id=#{parent_id}",
                                             "" ] if ingest_behavior_debug_verbose
      additional_parameters = {}
      additional_parameters.merge!( { called_from: called_from } ) if called_from.present?
      additional_parameters.merge!( { parent_id: parent_id } ) if parent_id.present?
      additional_parameters = nil if additional_parameters.empty?
      IngestStatus.new( cc_id: id,
                        cc_type: model_name.to_s,
                        status: IngestStatus::ATTACHED,
                        status_date: ::Hyrax::TimeService.time_in_utc,
                        additional_parameters: additional_parameters
                       ).save
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "" ] if ingest_behavior_debug_verbose
    end

    def ingest_attached?
      IngestStatus.ingest_attached?( cc_id: id )
    end

    def ingest_begin( called_from: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "called_from=#{called_from}",
                                             "" ] if ingest_behavior_debug_verbose
      additional_parameters = nil
      additional_parameters = { called_from: called_from } if called_from.present?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "self.class.name=#{self.class.name}",
      #                                        "id=#{id}",
      #                                        "called_from=#{called_from}",
      #                                        "cc_type=#{model_name.to_s}",
      #                                        "status=#{IngestStatus::STARTED}",
      #                                        "" ], bold_puts: true if true || ingest_behavior_debug_verbose
      IngestStatus.new( cc_id: id,
                        cc_type: model_name.to_s,
                        status: IngestStatus::STARTED,
                        status_date: ::Hyrax::TimeService.time_in_utc,
                        additional_parameters: additional_parameters,
                      ).save
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "" ] if ingest_behavior_debug_verbose
    end

    def ingest_end( called_from: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "called_from=#{called_from}",
                                             "" ] if ingest_behavior_debug_verbose
      additional_parameters = nil
      additional_parameters = { called_from: called_from } if called_from.present?
      IngestStatus.new( cc_id: id,
                        cc_type: model_name.to_s,
                        status: IngestStatus::FINISHED,
                        status_date: ::Hyrax::TimeService.time_in_utc,
                        additional_parameters: additional_parameters
                      ).save
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "id=#{id}",
                                             "" ] if ingest_behavior_debug_verbose
    end

    def ingest_finished?
      IngestStatus.ingest_finished?( cc_id: id )
    end

    def ingest_started?
      IngestStatus.ingest_started?( cc_id: id )
    end

    def ingesting?
      IngestStatus.ingesting?( cc_id: id )
    end

  end

end
