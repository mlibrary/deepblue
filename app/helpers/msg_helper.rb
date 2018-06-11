# frozen_string_literal: true

module MsgHelper
  extend ActionView::Helpers::TranslationHelper

  FIELD_SEP = '; '

  def self.creator( curration_concern, field_sep: FIELD_SEP )
    curration_concern.creator.join( field_sep )
  end

  def self.description( curration_concern, field_sep: FIELD_SEP )
    curration_concern.description.join( field_sep )
  end

  def self.globus_link( curration_concern )
    ::GlobusJob.external_url curration_concern.id
  end

  def self.publisher( curration_concern, field_sep: FIELD_SEP )
    curration_concern.publisher.join( field_sep )
  end

  def self.subject_discipline( curration_concern, field_sep: FIELD_SEP )
    curration_concern.subject_discipline.join( field_sep )
  end

  def self.title( curration_concern, field_sep: FIELD_SEP )
    curration_concern.title.join( field_sep )
  end

  def self.work_location( curration_concern: nil )
    # Rails.application.routes.url_helpers.hyrax_data_set_url( id: curration_concern.id )
    # Rails.application.routes.url_helpers.url_for( only_path: false,
    #                                               action: 'show',
    #                                               host: "http://todo.com",
    #                                               controller: 'concern/data_sets',
    #                                               id: id )
    "work location for: #{curration_concern.class.name} #{curration_concern.id}"
  end

end
