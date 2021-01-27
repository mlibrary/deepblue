# frozen_string_literal: true

module FindAndFixOverFileSetsBehavior

  FIND_AND_FIX_OVER_FILE_SETS_DEBUG_VERBOSE = false

  def find_and_fix_over_file_sets( messages:, ids_fixed: [], test_mode: false, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if FIND_AND_FIX_OVER_FILE_SETS_DEBUG_VERBOSE

    FileSet.all.each do |file_set|
      if file_set.parent.nil?
        messages << "#{file_set.id} parent is nil (over file sets)"
        next
      end
      if file_set.visibility != file_set.parent.visibility
        file_set.visibility = file_set.parent.visibility
        file_set.date_modified = DateTime.now
        file_set.save!( validate: false )
        ids_fixed << file_set.id
        messages << "FileSet #{file_set.id} parent work #{file_set.parent.id} updating visibility." if verbose
      end
    end

    messages << "FileSet ids found and fixed: #{ids_fixed}" unless ids_fixed.empty?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if FIND_AND_FIX_OVER_FILE_SETS_DEBUG_VERBOSE
  end

end
