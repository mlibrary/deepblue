# frozen_string_literal: true

module Deepblue

  class WorksTotalFileSizeFixer < AbstractFixer

    mattr_accessor :works_total_file_size_fixer_debug_verbose,
                   default: FindAndFixService.works_total_file_size_fixer_debug_verbose

    PREFIX = 'WorksTotalFileSizeFixer: '

    @solr_file_mismatch = false

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "" ] if works_total_file_size_fixer_debug_verbose && msg_handler.debug_verbose
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_total_file_size_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "" ] if debug_verbose
      return false unless curation_concern.respond_to? :file_sets
      return true if solr_file_size_mismatch?( curation_concern: curation_concern )
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "" ] if debug_verbose
      msg_handler.msg_verbose "fix work #{curation_concern.id} total file size"
      unless FindAndFixHelper.valid_file_sizes?( curation_concern: curation_concern, msg_handler: msg_handler )
        msg_verbose "Update total file size for work #{curation_concern.id}."
        FindAndFixHelper.fix_file_sizes( curation_concern: curation_concern, msg_handler: msg_handler )
      end
    end

  end

  def solr_file_size_mismatch?( curation_concern: )
    @solr_file_mismatch = false
    # doc = SolrDocument.find curation_concern.id
    doc = ::PersistHelper.find_solr( curation_concern.id, fail_if_not_found: false )
    return (@solr_file_mismatch = true) if doc.blank?
    solr_work_total_file_size = doc['total_file_size_lts']
    work_total_file_size = work.total_file_size
    return (@solr_file_mismatch = true) if work_total_file_size != solr_work_total_file_size
    file_set_total_size = work_total_file_set_solr_sizes( work: curation_concern )
    @solr_file_mismatch = solr_work_total_file_size != file_set_total_size
    return @solr_file_mismatch
  end

  def work_total_file_set_solr_sizes( work: )
    rv = 0
    work.file_sets.map.each do |f|
      doc = ::PersistHelper.find_solr( f.id, fail_if_not_found: false )
      next if doc.blank?
      file_size = doc['file_size_lts']
      next if file_size.blank?
      rv += file_size
    end
    return rv
  end

end

