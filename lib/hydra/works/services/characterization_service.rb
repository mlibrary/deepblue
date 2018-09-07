# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/characterization_service.rb" )

module Hydra::Works

  # monkey patch Hyrdra::Works::CharacterizationService

  # puts "monkey patching Hydra::Works::CharacterizationService"
  class CharacterizationService

    # monkey patch characterization_terms
    def characterization_terms( omdoc )
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
      # puts "\n>>>>>>>>>h[:file_mime_type]=#{h[:file_mime_type]}\n"
      h[:file_mime_type] = [h[:file_mime_type].first.split( ',' ).first] if h.key? :file_mime_type
      # puts "\n>>>>>>>>>h[:file_mime_type]=#{h[:file_mime_type]}\n"
      # end monkey patch
      h.delete_if { |_k, v| v.empty? }
    end

  end

end
