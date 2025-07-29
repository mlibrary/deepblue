# frozen_string_literal: true

require_relative '../../app/services/deepblue/valkyrie/disk'
require_relative '../../app/services/deepblue/valkyrie/valkyrie_simple_path_generator'

Valkyrie::StorageAdapter.register(
  ::Deepblue::Valkyrie::Storage::Disk.new( base_path: Hyrax.config.branding_path,
                              path_generator: ::Deepblue::ValkyrieSimplePathGenerator ),
  :branding_disk
)

Valkyrie::StorageAdapter.register(
  ::Deepblue::Valkyrie::Storage::Disk.new( base_path: Hyrax.config.derivatives_path,
                                          path_generator: Hyrax::DerivativeBucketedStorage ),
  :derivatives_disk
)
