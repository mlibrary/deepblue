# These events are triggered by actions within Hyrax Actors

HYRAX_CALLBACKS_DEBUG_VERBOSE = false
HYRAX_CALLBACKS_CALL_DEEPBLUE_EVENT_HELPER = false

Hyrax.config.callback.set(:after_create_concern) do |curation_concern, user|
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Callback: after_create_concern",
                                         "curation_concern.class.name=#{curation_concern.class.name}",
                                         "curation_concern.id=#{curation_concern.id}",
                                         "user=#{user}",
                                         "" ] if HYRAX_CALLBACKS_DEBUG_VERBOSE
  # ContentDepositEventJob.perform_later(curation_concern, user)
  # ::Deepblue::EventHelper.after_create_concern_callback( curation_concern: curation_concern, user: user ) if HYRAX_CALLBACKS_CALL_DEEPBLUE_EVENT_HELPER
end

Hyrax.config.callback.set(:after_create_fileset) do |file_set, user|
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Callback: after_create_concern",
                                         "file_set.id=#{file_set.id}",
                                         "user=#{user}",
                                         "" ], bold_puts: true if HYRAX_CALLBACKS_DEBUG_VERBOSE
  Hyrax::FileSetAttachedEventJob.perform_later(file_set, user)
  ::Deepblue::EventHelper.after_create_fileset_callback( file_set: file_set, user: user )
end

Hyrax.config.callback.set(:after_import_local_file_success) do |file_set, user, path|
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Callback: after_import_local_file_success",
                                         "file_set.id=#{file_set.id}",
                                         "user=#{user}",
                                         "path=#{path}",
                                         "" ] if HYRAX_CALLBACKS_DEBUG_VERBOSE
end

Hyrax.config.callback.set(:after_import_local_file_failure) do |file_set, user, path|
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "Callback: after_import_local_file_failure",
                                         "file_set.id=#{file_set.id}",
                                         "user=#{user}",
                                         "path=#{path}",
                                         "" ] if HYRAX_CALLBACKS_DEBUG_VERBOSE
end

# Hyrax.config.callback.set(:after_revert_content) do |file_set, user, revision|
#   ContentRestoredVersionEventJob.perform_later(file_set, user, revision)
#   ::Deepblue::EventHelper.after_revert_content_callback( file_set: file_set, user: user )
# end

# # :after_update_content callback replaced by after_perform block in IngestJob

# Hyrax.config.callback.set(:after_update_metadata) do |curation_concern, user|
#   ContentUpdateEventJob.perform_later(curation_concern, user)
#   ::Deepblue::EventHelper.after_update_metadata_callback( curation_concern: curation_concern, user: user )
# end

# Hyrax.config.callback.set(:after_destroy) do |id, user|
#   ContentDeleteEventJob.perform_later(id, user)
#   ::Deepblue::EventHelper.after_destroy_callback( id: id, user: user )
# end

# Hyrax.config.callback.set(:after_fixity_check_failure) do |file_set, checksum_audit_log:|
#   Hyrax::FixityCheckFailureService.new(file_set, checksum_audit_log: checksum_audit_log).call
#   ::Deepblue::EventHelper.after_fixity_check_failure_callback( file_set: file_set, checksum_audit_log: checksum_audit_log )
# end

# Hyrax.config.callback.set(:after_batch_create_success) do |user|
#   Hyrax::BatchCreateSuccessService.new(user).call
#   ::Deepblue::EventHelper.after_batch_create_succes_callback( curation_concern: curation_concern, user: user )
# end

# Hyrax.config.callback.set(:after_batch_create_failure) do |user, messages|
#   Hyrax::BatchCreateFailureService.new(user, messages).call
#   ::Deepblue::EventHelper.after_batch_create_failure_callback( user: user, msg: messages )
# end

# Hyrax.config.callback.set(:after_import_url_success) do |file_set, user|
#   # ImportUrlSuccessService was removed here since it's duplicative of
#   # the :after_create_fileset notification
# end

# Hyrax.config.callback.set(:after_import_url_failure) do |file_set, user|
#   Hyrax::ImportUrlFailureService.new(file_set, user).call
#   ::Deepblue::EventHelper.after_import_url_failure_callback( file_set: file_set, user: user )
# end
