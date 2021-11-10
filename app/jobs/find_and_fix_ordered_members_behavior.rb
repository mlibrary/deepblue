# frozen_string_literal: true

module FindAndFixOrderedMembersBehavior

  mattr_accessor :find_and_fix_all_ordered_members_nils_debug_verbose, default: false

  def find_and_fix_all_ordered_members_containing_nils( messages:,
                                                        ids_fixed: [],
                                                        filter:,
                                                        test_mode: true,
                                                        verbose: false )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "filter.class.name=#{filter.class.name}",
                                           "" ] if find_and_fix_all_ordered_members_nils_debug_verbose
    messages << "Started processing find_and_fix_all_ordered_members_containing_nils at #{DateTime.now}"

    ::PersistHelper.all.each do |curation_concern|
      next unless curation_concern.respond_to? :ordered_members
      if filter.present? && curation_concern.date_modified.present?
        next unless filter.include?( curation_concern.date_modified )
      end
      begin
        ordered_members = Array( curation_concern.ordered_members )
        next unless ordered_members.include? nil
        messages << "Compacting ordered_members for #{curation_concern.id}." if verbose
        ordered_members.compact
        curation_concern.ordered_members = ordered_members
        curation_concern.save!( validate: false )
        ids_fixed << curation_concern.id
      rescue Exception => e # rubocop:disable Lint/RescueException
        messages << "Error while processing #{curation_concern.id}: #{e.message} at #{e.backtrace[0]}"
      end
    end

    messages << "Curation concern ids found and fixed: #{ids_fixed}" unless ids_fixed.empty?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if find_and_fix_all_ordered_members_nils_debug_verbose
    messages << "Finished processing find_and_fix_all_ordered_members_containing_nils at #{DateTime.now}"
  end

end
