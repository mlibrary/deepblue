# frozen_string_literal: true

module Deepblue

  # check if file set size mismatch with solr
  class FileSetsFileSizeFixer < AbstractFixer

    mattr_accessor :file_sets_file_size_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_file_size_fixer_debug_verbose

    PREFIX = 'FileSet visibility: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = FileSetsFileSizeFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, msg_handler: msg_handler, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_visibility_fixer_debug_verbose || msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless solr_file_size_mismatch?( file_set: curation_concern )
      return false if curation_concern.ingesting?
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      buf = []
      buf << curation_concern.to_solr
      ActiveFedora::SolrService.add( buf, softCommit: true )
      ActiveFedora::SolrService.commit
      add_id_fixed curation_concern.id
    end

    def solr_file_size_mismatch?( file_set: )
      # doc = SolrDocument.find file_set.id
      doc = ::PersistHelper.find_solr( file_set.id, fail_if_not_found: false )
      return true if doc.blank?
      solr_file_size = doc['file_size_lts']
      return true if solr_file_size.nil?
      file_size = file_set.file_size
      rv = file_size != solr_file_size
      return rv
    end

  end

end
