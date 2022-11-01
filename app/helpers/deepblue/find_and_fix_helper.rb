# frozen_string_literal: true

module Deepblue

  module FindAndFixHelper

    mattr_accessor :find_and_fix_helper_debug_verbose, default: false

    def self.fix_file_sizes( id: nil, curation_concern: nil, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      msg_handler.msg_verbose "fix file sizes for work #{curation_concern&.id}"
      msg_handler.msg_verbose "w.present? #{w.present?}"
      selected = w.file_sets.select { |f| f.file_size.blank? }
      msg_handler.msg_verbose "selected.size = #{selected.size}"
      selected.each { |f| msg_handler.msg_verbose f.original_file_size } if msg_handler.to_console
      selected.each { |f| f.file_size = Array(f.original_file_size); f.save(validate: false) }
      selected.each { |f| f.reload }
      selected.each { |f| msg_handler.msg_verbose Array(f.file_size) }
      w.reload
      sizes = w.file_sets.map { |f| f.file_size }
      if sizes.include? []
        selected.each do |f|
          force_update_to_file_size( file_set: f, msg_handler: msg_handler ) if f.file_size.blank?
        end
      end
      w.reload
      msg_handler.msg_verbose "file_sets.map { |f| f.file_size } = #{sizes}"
      solr_reindex_work_with_total_size_update( id: w.id, msg_handler: msg_handler )
    end

    def self.force_update_to_file_size( file_set:, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      msg_handler.msg_verbose "forcing file size update to file set: #{file_set.id}"
      sparql_update_template=<<-END_OF_BODY
PREFIX ebucore: <http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#>
INSERT {
  <> ebucore:fileSize "NEW_METADATA" .
}
WHERE { }
      END_OF_BODY
      # find the first candidate file with blank size
      found = nil
      file_set.files.each do |f|
        if f.file_size.empty?
          found = f
          break
        end
      end
      return false unless found.present?
      uri = found.uri.value
      uri_metadata = "#{uri}/fcr:metadata"
      msg_handler.msg_verbose "#{uri_metadata}"
      sparql_update = sparql_update_template.sub( 'NEW_METADATA', file_set.original_file.size.to_s )
      rv = ActiveFedora.fedora.connection.patch( uri_metadata,
                                                 sparql_update,
                                                 "Content-Type" => "application/sparql-update" )
      msg_handler.msg_verbose "Updated file size returned status #{rv.status}"
      file_set.date_modified = DateTime.now
      file_set.save!( validate: false )
      # file_set.parent.update_total_file_size!
      true
    end

    def self.solr_reindex_work_with_total_size_update( id: nil, curation_concern: nil, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      msg_handler.msg_verbose "w.present? #{w.present?}"
      file_sets = w.file_sets
      batch = []
      file_sets.each { |f| batch << f.to_solr }
      ActiveFedora::SolrService.add(batch, softCommit: true)
      ActiveFedora::SolrService.commit
      w.update_total_file_size!
      batch = []
      batch << w.to_solr
      ActiveFedora::SolrService.add(batch, softCommit: true)
      ActiveFedora::SolrService.commit
    end

    def self.resolve_curation_concern( id: nil, curation_concern: nil )
      return curation_concern if curation_concern.present?
      ::PersistHelper.find id
    end

    def self.resolve_curation_concern_solr( id: nil, curation_concern: nil )
      id = curation_concern.id if id.blank? && curation_concern.present?
      SolrDocument.find id
    end

    # add solr check
    def self.valid_file_sizes?( id: nil, curation_concern: nil, check_solr: true, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      msg_handler.msg_verbose "w.present? #{w.present?}"
      sizes = w.file_sets.map { |f| f.file_size }
      msg_handler.msg_verbose "file_sets.map { |f| f.file_size } = #{sizes}"
      return false if sizes.include? []
      return true unless check_solr
      sizes = w.file_sets.map { |f| doc = ::SolrDocument.find f.id; doc['file_size_lts'] }
      msg_handler.msg_verbose "file_sets.map of solr docs = #{sizes}"
      return true
    end

    def self.valid_ordered_members?( id: nil, curation_concern: nil, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      msg_handler.msg_verbose "w.present? #{w.present?}"
      return false unless w.present?
      a = Array(w.ordered_members)
      msg_handler.msg_verbose "w.present? #{w.present?}"
      return false if a.include? nil
      msg_handler.msg_verbose "ordered_members.size = #{a.size}"
      msg_handler.msg_verbose "file_sets.size = #{w.file_sets.size}"
      msg_handler.msg_verbose "file_sets.size == a.size = #{w.file_sets.size == a.size}"
      return w.file_sets.size == a.size
    end

  end

end
