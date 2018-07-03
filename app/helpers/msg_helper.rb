# frozen_string_literal: true

module MsgHelper
  extend ActionView::Helpers::TranslationHelper

  FIELD_SEP = '; '

  def self.creator( curation_concern, field_sep: FIELD_SEP )
    curation_concern.creator.join( field_sep )
  end

  def self.description( curation_concern, field_sep: FIELD_SEP )
    curation_concern.description.join( field_sep )
  end

  def self.globus_link( curation_concern )
    ::GlobusJob.external_url curation_concern.id
  end

  def self.publisher( curation_concern, field_sep: FIELD_SEP )
    curation_concern.publisher.join( field_sep )
  end

  def self.subject_discipline( curation_concern, field_sep: FIELD_SEP )
    curation_concern.subject_discipline.join( field_sep )
  end

  def self.title( curation_concern, field_sep: FIELD_SEP )
    curation_concern.title.join( field_sep )
  end

  def self.work_location( curation_concern: nil )
    # Rails.application.routes.url_helpers.hyrax_data_set_url( id: curation_concern.id )
    # Rails.application.routes.url_helpers.url_for( only_path: false,
    #                                               action: 'show',
    #                                               host: "http://todo.com",
    #                                               controller: 'concern/data_sets',
    #                                               id: id )
    "work location for: #{curation_concern.class.name} #{curation_concern.id}"
  end

end
