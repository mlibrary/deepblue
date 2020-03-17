# frozen_string_literal: true

module Deepblue

  module WorkViewContentService

    @@_setup_ran = false

    @@documentation_collection_title = nil
    mattr_accessor :documentation_collection_title

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
