# frozen_string_literal: true

module Deepblue

  # check if file set size mismatch with solr
  class FileSetsFileSizeFixer < AbstractFixer

    mattr_accessor :file_sets_file_size_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_file_size_fixer_debug_verbose

    PREFIX = 'FileSet visibility: '

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, msg_handler: msg_handler, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_visibility_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless solr_file_size_mismatch?( file_set: curation_concern )
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      buf = []
      buf << curation_concern.to_solr
      ActiveFedora::SolrService.add( buf, softCommit: true )
      ActiveFedora::SolrService.commit
    end

    def solr_file_size_mismatch?( file_set: )
      # doc = SolrDocument.find curation_concern.id
      doc = ::PersistHelper.find_solr( curation_concern.id, fail_if_not_found: false )
      return true if doc.blank?
      solr_file_size = doc['file_size_lts']
      return true if solr_file_size.nil?
      file_size = file_set.file_size
      rv = file_size != solr_file_size
      return rv
    end

  end

end
