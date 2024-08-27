# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax::Forms

  class FileSetEditForm
    include HydraEditor::Form
    include HydraEditor::Form::Permissions

    delegate :depositor, :permissions, :human_readable_type, to: :model

    self.required_fields = [:title, :creator, :keyword, :license]

    self.model_class = ::FileSet

    self.terms = [:resource_type,
                  :title,
                  :creator,
                  :contributor,
                  :description,
                  :keyword,
                  :license,
                  :publisher,
                  :date_created,
                  :subject,
                  :language,
                  :identifier,
                  :based_near,
                  :related_url,
                  :visibility_during_embargo,
                  :visibility_after_embargo,
                  :embargo_release_date,
                  :visibility_during_lease,
                  :visibility_after_lease,
                  :lease_expiration_date,
                  :visibility]

    # term additions
    self.terms += %i[ curation_notes_admin
                      curation_notes_user
                      description_file_set ]

    # copied from heliotrope for reference - FF
    # # RE: below methods, see https://samvera.github.io/customize-metadata-other-customizations.html
    # # TODO: copy this to fix up some other Hyrax::BasicMetadata fields on FileSets which are undesirably multi-valued
    # def self.multiple?(field)
    #   if %i[license].include? field.to_sym
    #     false
    #   else
    #     super
    #   end
    # end
    #
    # def self.model_attributes(_nil)
    #   attrs = super
    #   attrs[:license] = Array(attrs[:license]) if attrs[:license]
    #   attrs
    # end
    #
    # def license
    #   super.first || ""
    # end

  end

end
