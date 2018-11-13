# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/characterization_service.rb" )

module Hydra::Works

  # monkey patch Hyrdra::Works::CharacterizationService

  # puts "monkey patching Hydra::Works::CharacterizationService"
  class CharacterizationService

    # monkey patch characterization_terms
    def characterization_terms( omdoc )
      # puts;puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CharacterizationService.characterization_terms";puts
      h = {}
      omdoc.class.terminology.terms.each_pair do |key, target|
        # a key is a proxy if its target responds to proxied_term
        next unless target.respond_to? :proxied_term
        begin
          h[key] = omdoc.send(key)
        rescue NoMethodError
          next
        end
      end
      # begin monkey patch
      h = clean_and_override_mime_type( h )
      # end monkey patch
      h.delete_if { |_k, v| v.empty? }
    end

    def clean_and_override_mime_type( h )
      return h unless h.key? :file_mime_type
      # puts "\n>>>>>>>>>h[:file_mime_type]=#{h[:file_mime_type]}\n"
      # make sure mime_type does not contain a comma, like: "mime/type,mime/type"
      h[:file_mime_type] = [h[:file_mime_type].first.split( ',' ).first]
      # TODO: should log this if a comma is found
      # puts "\n>>>>>>>>>h[:file_mime_type]=#{h[:file_mime_type]}\n"
      fname = file_name
      file_ext = File.extname fname
      # puts "\n>>>>>>>>>fname=#{fname}, file_ext=#{file_ext}\n"
      if DeepBlueDocs::Application.config.characterize_excluded_ext_set.key? file_ext
        # TODO: should log this if the enforced mime type is different than the one determined
        enforced_mime_type = DeepBlueDocs::Application.config.characterize_enforced_mime_type[file_ext]
        h[:file_mime_type] = enforced_mime_type
        # puts "\n>>>>>>>>>enforced mime type h[:file_mime_type]=#{h[:file_mime_type]}\n"
      end
      return h
    end

  end

end
