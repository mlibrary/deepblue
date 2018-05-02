module MsgHelper
  extend ActionView::Helpers::TranslationHelper

  @@FIELD_SEP = '; '.freeze

  def self.creator( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.creator.join( field_sep )
  end

  def self.description( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.description.join( field_sep )
  end

  def self.globus_link( curration_concern )
    ::GlobusJob.external_url curration_concern.id
  end

  def self.publisher( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.publisher.join( field_sep )
  end

  def self.subject( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.subject.join( field_sep )
  end

  def self.title( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.title.join( field_sep )
  end

  def self.work_location( curration_concern )
    Rails.application.routes.url_helpers.hyrax_generic_work_url( id: curration_concern.id )
  end

end
