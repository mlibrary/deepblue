# frozen_string_literal: true

module Dataset::Forms
  class WorkForm < Hyrax::Forms::WorkForm

    # self.terms += [ :authoremail, :date_coverage, :fundedby, :grantnumber, :referenced_by, :methodology, :on_behalf_of]

    # class << self
    #   # This determines whether the allowed parameters are single or multiple.
    #   # By default it delegates to the model, but we need to override for
    #   # 'rights' which only has a single value on the form.
    #   def multiple?(term)
    #     case term.to_s
    #       when 'rights'
    #         false
    #       when 'fundedby'
    #         false
    #       else
    #         super
    #     end
    #   end
    #
    #   # Overriden to cast 'rights' to an array
    #   def sanitize_params(form_params)
    #     super.tap do |params|
    #       params['rights_license'] = Array(params['rights_license']) if params.key?('rights_license')
    #       params['subject'] = Array(params['subject']) if params.key?('subject')
    #       params['fundedby'] = Array(params['fundedby']) if params.key?('fundedby')
    #     end
    #   end
    # end
    #
    # def rights
    #     @model.rights_license.first
    # end
    #

  end
end
