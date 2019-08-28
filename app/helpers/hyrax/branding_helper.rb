# frozen_string_literal: true

module Hyrax

  module BrandingHelper

    def branding_banner_file( id: )
      # Find Banner filename
      ci = CollectionBrandingInfo.where( collection_id: id, role: "banner" )
      brand_path( collection_branding_info: ci[0] ) unless ci.empty?
    end

    def branding_logo_record( id: )
      logo_info = []
      # Find Logo filename, alttext, linktext
      cis = CollectionBrandingInfo.where( collection_id: id, role: "logo" )
      return if cis.empty?
      cis.each do |coll_info|
        logo_file = File.split(coll_info.local_path).last
        file_location = brand_path( collection_branding_info: coll_info ) unless logo_file.empty?
        alttext = coll_info.alt_text
        linkurl = coll_info.target_url
        logo_info << { file: logo_file, file_location: file_location, alttext: alttext, linkurl: linkurl }
      end
      logo_info
    end

    def brand_path( collection_branding_info: )
      rv = collection_branding_info
      local_path = collection_branding_info.local_path
      return rv if local_path.blank?
      local_path_relative = local_path.split("/")[-4..-1].join('/')
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "collection_branding_info = #{collection_branding_info}",
                                             "local_path = #{local_path}",
                                             "local_path_relative=#{local_path_relative}",
                                             "" ]
      rv = ::DeepBlueDocs::Application.config.relative_url_root + "/" + local_path_relative
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv = #{rv}",
                                             "" ]
      return rv
    end

    def branding_banner_info( id: )
      @banner_info ||= begin
                         # Find Banner filename
        banner_info = collection_banner_info( id: id )
        banner_file = File.split(banner_info.first.local_path).last unless banner_info.empty?
        file_location = banner_info.first.local_path unless banner_info.empty?
        relative_path = brand_path( collection_branding_info: banner_info.first ) unless banner_info.empty?
        { file: banner_file, full_path: file_location, relative_path: relative_path }
      end
    end

    def branding_logo_info( id: )
      @logo_info ||= begin
                       # Find Logo filename, alttext, linktext
        logos_info = collection_logo_info( id: id )
        logos_info.map do |logo_info|
          logo_file = File.split(logo_info.local_path).last
          relative_path = brand_path( collection_branding_info: logo_info ) unless logo_file.empty?
          alttext = logo_info.alt_text
          linkurl = logo_info.target_url
          { file: logo_file, full_path: logo_info.local_path, relative_path: relative_path, alttext: alttext, linkurl: linkurl }
        end
      end
    end

    def collection_banner_info( id: )
      CollectionBrandingInfo.where( collection_id: id.to_s ).where( role: "banner" )
    end

    def collection_logo_info( id: )
      CollectionBrandingInfo.where( collection_id: id.to_s ).where( role: "logo" )
    end

    def branding_file_save( collection_branding_info:, file_location:, copy_file: true )
      local_dir = branding_file_find_local_dir_name( collection_id: collection_id, role: role )
      FileUtils.mkdir_p local_dir
      local_path = collection_branding_info.local_path
      FileUtils.cp file_location, local_path unless file_location == local_path || !copy_file
      FileUtils.remove_file(file_location) if File.exist?(file_location) && copy_file
      super()
    end

    def branding_file_delete( location_path: )
      FileUtils.remove_file( location_path ) if File.exist?( location_path )
    end

    def branding_file_find_local_filename( collection_id:, role:, filename: )
      local_dir = branding_file_find_local_dir_name( collection_id: collection_id, role: role )
      File.join(local_dir, filename)
    end

    def branding_file_find_local_dir_name( collection_id:, role: )
      File.join( Hyrax.config.branding_path, collection_id.to_s, role.to_s)
    end

  end

end
