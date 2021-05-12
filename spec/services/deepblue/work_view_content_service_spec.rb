# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::WorkViewContentService do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.interpolation_helper_debug_verbose ).to eq false
      expect( described_class.static_content_controller_behavior_verbose ).to eq( false )
      expect( described_class.static_content_cache_debug_verbose ).to eq( false )
      expect( described_class.work_view_documentation_controller_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_email_templates_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_i18n_templates_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_view_templates_debug_verbose ).to eq( false )
    end
  end

  describe 'other module values' do
    it "resolves them" do
      expect( described_class.documentation_collection_title ).to eq "DBDDocumentationCollection"
      expect( described_class.documentation_work_title_prefix ).to eq "DBDDoc-"
      expect( described_class.documentation_email_title_prefix ).to eq "DBDEmail-"
      expect( described_class.documentation_i18n_title_prefix ).to eq "DBDI18n-"
      expect( described_class.documentation_view_title_prefix ).to eq "DBDView-"
      expect( described_class.export_documentation_path ).to eq '/tmp/documentation_export'

      expect( described_class.static_content_controller_behavior_menu_verbose ).to eq false
      expect( described_class.static_content_enable_cache ).to eq true
      expect( described_class.static_content_interpolation_pattern ).to eq /(?-mix:%%)|(?-mix:%\{([\w|]+)\})|(?-mix:%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps]))/
      expect( described_class.static_controller_redirect_to_work_view_content ).to eq false
    end
  end

end
