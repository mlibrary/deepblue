# frozen_string_literal: true

module Umrdr::Forms
  class WorkForm < Hyrax::Forms::WorkForm

    # self.terms += [ :authoremail, :date_coverage, :fundedby, :grantnumber, :isReferencedBy, :methodology, :on_behalf_of]

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
    #       params['rights_statement'] = Array(params['rights_statement']) if params.key?('rights_statement')
    #       params['subject'] = Array(params['subject']) if params.key?('subject')
    #       params['fundedby'] = Array(params['fundedby']) if params.key?('fundedby')
    #     end
    #   end
    # end
    #
    # def rights
    #     @model.rights_statement.first
    # end
    #
    # # You like danger?! Because you better pass in a hash with the correct keys.
    # # Can be alleviated when form coverage attribute is:
    # # `coverages: [{begin: {:year, :month, :day}, end: {:year, :month, :day}}, ... ]`
    # def merge_date_coverage_attributes!(hsh)
    #   @attributes.merge!(hsh&.stringify_keys || {})
    # end

  end
end
