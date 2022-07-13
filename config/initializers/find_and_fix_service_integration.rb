
Deepblue::FindAndFixService.setup do |config|

  config.find_and_fix_service_debug_verbose             = false
  config.abstract_fixer_debug_verbose                   = false
  config.file_sets_lost_and_found_fixer_debug_verbose   = false
  config.file_sets_visibility_fixer_debug_verbose       = false
  config.find_and_fix_job_debug_verbose                 = false
  config.find_and_fix_empty_file_sizes_debug_verbose    = false
  config.find_and_fix_job_debug_verbose                 = false
  config.works_ordered_members_file_sets_size_fixer_debug_verbose = false
  config.works_ordered_members_nils_fixer_debug_verbose = false

  config.find_and_fix_default_filter   = nil
  config.find_and_fix_default_verbose  = true
  config.find_and_fix_over_collections = []
  config.find_and_fix_over_file_sets   = [ 'Deepblue::FileSetsLostAndFoundFixer',
                                           'Deepblue::FileSetsVisibilityFixer' ]
  config.find_and_fix_over_works       = [ 'Deepblue::WorksOrderedMembersNilsFixer',
                                           'Deepblue::WorksOrderedMembersFileSetsSizeFixer',
                                           'Deepblue::WorksTotalFileSizeFixer' ]

  config.find_and_fix_file_sets_lost_and_found_work_title = 'DBD_Find_and_Fix_FileSets_Lost_and_Found'

  config.find_and_fix_subscription_id = 'find_and_fix_subscription'

end