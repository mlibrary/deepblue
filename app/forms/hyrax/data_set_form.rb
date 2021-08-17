# frozen_string_literal: true

module Hyrax

  class DataSetForm < DeepblueForm

    mattr_accessor :data_set_forms_debug_verbose, default: false

    self.model_class = ::DataSet

    self.terms -= %i[ rights_statement ]
    self.terms +=
      %i[
        authoremail
        date_coverage
        description
        fundedby
        fundedby_other
        doi
        grantnumber
        keyword
        methodology
        tombstone
        referenced_by
        rights_license
        rights_license_other
        subject_discipline
        curation_notes_admin
        curation_notes_user
        access_deepblue
      ]

    self.default_work_primary_terms =
      %i[
        title
        creator
        authoremail
        methodology
        tombstone
        description
        date_coverage
        rights_license
        rights_license_other
        subject_discipline
        fundedby
        fundedby_other
        grantnumber
        keyword
        language
        referenced_by
        curation_notes_admin
        curation_notes_user
        access_deepblue
      ]

    self.default_work_secondary_terms = []

    self.required_fields =
      %i[
        title
        creator
        authoremail
        methodology
        description
        rights_license
        subject_discipline
      ]

    def data_set?
      true
    end

    def merge_date_coverage_attributes!(hsh)
      @attributes.merge!(hsh&.stringify_keys || {})
    end

    # Return a hash of all the parameters from the form as a hash.
    # This is typically used by the controller as the main read interface to the form.
    # This hash can then be used to create or update an object in the data store.
    # example:
    #   ImageForm.model_attributes(params[:image])
    #   # => { title: 'My new image' }
    def self.model_attributes_json( form_params:, curation_concern: )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "form_params=#{form_params}",
                                             "" ] if data_set_forms_debug_verbose
      rv = sanitize_params_json( form_params: form_params, curation_concern: curation_concern ).tap do |clean_params|
        terms.each do |key|
          if clean_params[key]
            if multiple?(key)
              clean_params[key].delete('')
            elsif clean_params[key] == ''
              clean_params[key] = nil
            end
          end
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             # "permitted_params=#{pparms}",
                                             "form_params.errors=#{form_params.errors}",
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "rv.errors=#{rv.errors}",
                                             "" ] if data_set_forms_debug_verbose
      return rv
    end

    def self.sanitize_params_from_form_class( form_params )
      pparms = permitted_params
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "form_params.class.name=#{form_params.class.name}",
                                             "form_params=#{form_params}",
                                             "form_params.errors=#{form_params.errors}",
                                             "permitted_params.class.name=#{pparms.class.name}",
                                             # "permitted_params=#{pparms}",
                                             "" ] if data_set_forms_debug_verbose
      rv = form_params.permit(*pparms)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             # "permitted_params=#{pparms}",
                                             "form_params.errors=#{form_params.errors}",
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "rv.errors=#{rv.errors}",
                                             "" ] if data_set_forms_debug_verbose
      return rv
    end

    def self.sanitize_params_json( form_params:, curation_concern: )
      admin_set_id = form_params[:admin_set_id]
      return sanitize_params_from_form_class(form_params) if admin_set_id && workflow_for(admin_set_id: admin_set_id).allows_access_grant?
      params_without_permissions = permitted_params.reject { |arg| arg.respond_to?(:key?) && arg.key?(:permissions_attributes) }
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params_without_permissions=#{params_without_permissions}",
                                             "form_params.errors=#{form_params.errors}",
                                             "form_params=#{form_params}",
                                             "" ] if data_set_forms_debug_verbose
      rv = form_params.permit(*params_without_permissions)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "form_params.errors=#{form_params.errors}",
                                             "params_without_permissions=#{params_without_permissions}",
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "" ] if data_set_forms_debug_verbose
      return rv
    end

    def self.multiple?(field)
      field_metadata_service.multiple?(model_class, field)
    end


  end

end
