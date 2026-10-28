# frozen_string_literal: true

# Deep Blue Data OAI identifiers are oai:deepblue.lib.umich.edu:data/<id>
#
# blacklight_oai_provider patches these two methods (config/initializers/oai_patches.rb in the gem)
# to build identifiers as "<record_prefix>:<id>". Override them to add the record_local_prefix
# ('data/') from CatalogController's oai config. This to_prepare block is registered after the gem's,
# so it runs after it and wins.
#
# Check this still applies when upgrading blacklight_oai_provider or oai.

Rails.application.config.to_prepare do
  OAI::Provider::Response::RecordResponse.class_eval do
    private

    def identifier_for(record)
      "#{provider.prefix}:#{CatalogController.blacklight_config.oai[:provider][:record_local_prefix]}#{record.id}"
    end
  end

  OAI::Provider::Response::Base.class_eval do
    private

    def extract_identifier(id)
      id.sub("#{provider.prefix}:#{CatalogController.blacklight_config.oai[:provider][:record_local_prefix]}", '')
    end
  end
end
