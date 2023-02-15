# frozen_string_literal: true

module DeepbluePresenterHelper

  mattr_accessor :deepblue_presenter_helper_debug_verbose, default: false

  def self.ld_json_creator( curation_concern )
    if curation_concern.respond_to? :parent
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.parent.class.name=#{curation_concern.parent.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      authors = curation_concern.parent.creator
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      authors = curation_concern.creator
    end
    rv = []
    authors.each do |author|
      rv << "{ \"@type\": \"Person\", \"name\": \"#{author}\" }"
    end
    return rv.join(',')
  end

  def self.ld_json_description( curation_concern )
    rv = curation_concern.description.join(";")
    len = rv.size
    # description should be between 50 and 5000 characters in length
    rv = rv.substring( 0, 4999 ) if len > 4999
    rv = rv + " - This data set has been deposited in Deepblue Data." if len < 50
    return rv
  end

  def self.ld_json_identifier( curation_concern )
    rv = ''
    rv = curation_concern.doi if curation_concern.respond_to?( :doi ) && curation_concern.doi.present?
    return rv
  end

  def self.ld_json_license( curation_concern )
    rv = "{ \"@type\": \"CreativeWork\",\"name\": \"#{ld_json_license_name( curation_concern )}\",\"license\": \"#{ld_json_license_url( curation_concern )}\" }"
    return rv
  end

  def self.ld_json_license_name( curation_concern )
    if curation_concern.respond_to? :parent
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.parent.class.name=#{curation_concern.parent.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      license = curation_concern.parent.rights_license
      license_other = curation_concern.parent.rights_license_other
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      license = curation_concern.rights_license
      license_other = curation_concern.rights_license_other
    end
    if license == 'http://creativecommons.org/publicdomain/zero/1.0/'
      rv = 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication'
    elsif license == 'http://creativecommons.org/licenses/by/4.0/'
      rv = 'Attribution 4.0 International (CC BY 4.0)'
    elsif license == 'http://creativecommons.org/licenses/by-nc/4.0/'
      rv = 'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)'
    elsif license.blank?
      rv = ''
    elsif 'Other' == license && license_other.present?
      rv = license_other
    else
      rv = license
    end
    return rv
  end

  def self.ld_json_license_url( curation_concern )
    if curation_concern.respond_to? :parent
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.parent.class.name=#{curation_concern.parent.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      license = curation_concern.parent.rights_license
      license_other = curation_concern.parent.rights_license_other
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "" ] if deepblue_presenter_helper_debug_verbose
      license = curation_concern.rights_license
      license_other = curation_concern.rights_license_other
    end
    if license.blank?
      rv = ''
    elsif 'Other' == license && license_other.present?
      rv = license_other
    else
      rv = license
    end
    return rv
  end

end
