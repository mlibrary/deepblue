# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/characterization_service.rb" )

module Hydra::Works

  # monkey patch Hyrdra::Works::CharacterizationService

  # puts "monkey patching Hydra::Works::CharacterizationService"
  class CharacterizationService

    # Get given source into form that can be passed to Hydra::FileCharacterization
    # Use Hydra::FileCharacterization to extract metadata (an OM XML document)
    # Get the terms (and their values) from the extracted metadata
    # Assign the values of the terms to the properties of the object
    def characterize
      content = source_to_content
      extracted_md = extract_metadata(content)
      terms = parse_metadata(extracted_md)
      store_metadata(terms)
    end

    # monkey patch characterization_terms
    def characterization_terms( omdoc )
      # puts;puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CharacterizationService.characterization_terms";puts
      h = {}
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( "omdoc", omdoc ),
                                           "omdoc=#{omdoc}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      keys = []
      omdoc.class.terminology.terms.each_pair do |key, target|
        keys << key
        # a key is a proxy if its target responds to proxied_term
        next unless target.respond_to? :proxied_term
        begin
          h[key] = omdoc.send(key)
        rescue NoMethodError
          next
        end
      end
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "keys=#{keys}",
                                           "h=#{JSON.pretty_generate(h)}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      # begin monkey patch
      h = clean_and_override_mime_type( h )
      # end monkey patch
      h.delete_if { |_k, v| v.empty? }
    end

    def clean_and_override_mime_type( h )
      return h unless h.key? :file_mime_type
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "h[:file_mime_type]=#{h[:file_mime_type]}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      # make sure mime_type does not contain a comma, like: "mime/type,mime/type"
      h[:file_mime_type] = [h[:file_mime_type].first.split( ',' ).first]
      h[:format_label] = [h[:format_label].first.split( ',' ).first]
      # TODO: should log this if a comma is found
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "h[:file_mime_type]=#{h[:file_mime_type]}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      fname = file_name
      file_ext = File.extname fname
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "fname=#{fname}",
                                           "file_ext=#{file_ext}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      if Deepblue::IngestIntegrationService.characterize_mime_type_ext_mismatch.key? h[:file_mime_type].first
        fixed_mime_type = Array( Deepblue::IngestIntegrationService.characterize_mime_type_ext_mismatch_fix[file_ext] )
        h[:file_mime_type] = fixed_mime_type
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "fixed mime type",
                                             "h[:file_mime_type]=#{h[:file_mime_type]}",
                                             "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      elsif Deepblue::IngestIntegrationService.characterize_excluded_ext_set.key? file_ext
        # TODO: should log this if the enforced mime type is different than the one determined
        enforced_mime_type = Array( Deepblue::IngestIntegrationService.characterize_enforced_mime_type[file_ext] )
        h[:file_mime_type] = enforced_mime_type
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "enforced mime type",
                                             "h[:file_mime_type]=#{h[:file_mime_type]}",
                                             "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      end
      return h
    end

    def extract_metadata(content)
      Hydra::FileCharacterization.characterize(content, file_name, tools) do |cfg|
        cfg[:fits] = Hydra::Derivatives.fits_path
      end
    end

    # Use OM to parse metadata
    def parse_metadata(metadata)
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( "metadata", metadata ),
                                           "metadata=#{metadata}",
                                           "" ] if Deepblue::IngestIntegrationService.characterization_service_debug_verbose
      omdoc = parser_class.new
      omdoc.ng_xml = Nokogiri::XML(metadata) if metadata.present?
      omdoc.__cleanup__ if omdoc.respond_to? :__cleanup__
      characterization_terms(omdoc)
    end

  end

end
