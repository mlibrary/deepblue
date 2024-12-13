#hyrax5 - removed Willowsword due failure to find compatible gems
# WillowSword.setup do |config|
#
#   config.willow_sword_integration_service_debug_verbose = false
#
#   # See: https://github.com/CottageLabs/willow_sword/wiki/Configuring-willow-sword
#
#   # The title used by the sword server, in the service document
#   config.title = 'Deep Blue Data Sword V2 server'
#   # If you do not want to use collections in Sword, it will use this as a default collection
#   # This is the default collection in production
#   # config.default_collection = {id: '5999n365p', title: ['SWORDDefaultCollection']}
#   config.default_collection = {id: 'default', title: ['SWORDDefaulCollection']}
#   # The name of the model for retreiving collections (based on Hyrax integration)
#   config.collection_models = ['Collection']
#   # The work models supported by Sword (based on Hyrax integration)
#   config.work_models = ['DataSet']
#   # The fileset model supported by Sword (based on Hyrax integration)
#   config.file_set_models = ['FileSet']
#   # Remove all parameters that are not part of the model's permitted attributes
#   config.allow_only_permitted_attributes = true
#   # Default visibility for works
#   config.default_visibility = 'open'
#   # Metadata filename in payload
#   config.metadata_filename = 'metadata.xml'
#   # XML crosswalk for creating a work
#   config.xw_from_xml_for_work = WillowSword::CrosswalkFromDcData
#   # XML crosswalk for creating a fileset
#   config.xw_from_xml_for_fileset = WillowSword::CrosswalkFromDc
#   # XML crosswalk when requesting a work
#   config.xw_to_xml_for_work = WillowSword::CrosswalkWorkToDc
#   # XML crosswalk when requesting a fileet
#   config.xw_to_xml_for_fileset = WillowSword::CrosswalkFilesetToDc
#   # Authorize Sword requests using Api-key header
#   config.authorize_request = true
#
#   config.default_collection_title = 'SWORDDefaultCollection'
#
# end
