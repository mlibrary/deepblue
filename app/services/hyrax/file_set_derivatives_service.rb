# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/services/hyrax/file_set_derivatives_service.rb")
module Hyrax
  # monkey patch
  class FileSetDerivativesService
    alias_method :monkey_create_derivatives, :create_derivatives
    alias_method :monkey_create_pdf_derivatives, :create_pdf_derivatives
    alias_method :monkey_create_office_document_derivatives, :create_office_document_derivatives

    def create_derivatives(filename)
      begin
        Rails.logger.debug "About to call create_derivatives(#{filename})"
        monkey_create_derivatives(filename)
        Rails.logger.debug "Returned from call create_derivatives(#{filename})"
      rescue Exception => e
        Rails.logger.error "create_derivatives error #{filename} - #{e.class}: #{e.message}"
      end
    end

    def create_pdf_derivatives(filename)
      monkey_create_pdf_derivatives(filename)
    end

    def create_office_document_derivatives(filename)
      monkey_create_office_document_derivatives(filename)
    end

    ## This has problems:
    # mp_create_derivatives = instance_method(:create_derivatives)
    #
    # define_method(:create_derivatives) do |filename|
    #   create_derivatives_with_rescue(filename)
    # end
    #
    # def create_derivatives_with_rescue(filename)
    #   Rails.logger.warn "About to call create_derivatives(" + filename + ")"
    #   mp_create_derivatives.bind(self).(filename)
    #   Rails.logger.warn "Returned from call create_derivatives(" + filename + ")"
    # rescue Exception => e
    #   Rails.logger.error "create_derivatives(" + filename + ") exception: " + e
    # end

  end
end
