# frozen_string_literal: true

module FindAndFixOverFileSetsBehavior

  mattr_accessor :find_and_fix_over_file_sets_debug_verbose, default: false

  def find_and_fix_over_file_sets( msg_handler:,
                                   ids_fixed: [],
                                   filter:,
                                   test_mode: false,
                                   verbose: false )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "msg_handler=#{msg_handler}",
                                           "ids_fixed=#{ids_fixed}",
                                           "filter.class.name=#{filter.class.name}",
                                           "" ] if find_and_fix_over_file_sets_debug_verbose

    msg_handler.msg "Started processing find_and_fix_over_file_sets at #{DateTime.now}"

    FileSet.all.each do |file_set|
      curation_concern = file_set.parent
      if curation_concern.nil?
        msg_handler.msg "#{file_set.id} parent is nil (over file sets)"
        next
      end
      if filter.present? && curation_concern.date_modified.present?
        next unless filter.include?( curation_concern.date_modified )
      end
      if file_set.visibility != curation_concern.visibility
        file_set.visibility = curation_concern.visibility
        file_set.date_modified = DateTime.now
        file_set.save!( validate: false )
        ids_fixed << file_set.id
        msg_handler.msg_verbose "FileSet #{file_set.id} parent work #{curation_concern.id} updating visibility."
      end
    end

    msg_handler.msg "FileSet ids found and fixed: #{ids_fixed}" unless ids_fixed.empty?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "msg_handler=#{msg_handler}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if find_and_fix_over_file_sets_debug_verbose
    msg_handler.msg "Finished processing find_and_fix_over_file_sets at #{DateTime.now}"
  end

end
