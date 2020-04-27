# frozen_string_literal: true

module Deepblue

  module WorkViewContentService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false

    @@documentation_collection_title = "DBDDocumentationCollection"
    mattr_accessor :documentation_collection_title

    @@documentation_work_title_prefix = "DBDDoc-"
    mattr_accessor :documentation_work_title_prefix


    @@static_controller_redirect_to_work_view_content = false
    mattr_accessor :static_controller_redirect_to_work_view_content


    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    def documentation_collection_title
      @@documentation_collection_title
    end

    def work_view_content_enable_cache
      ::DeepBlueDocs::Application.config.static_content_enable_cache
    end

  end

end
