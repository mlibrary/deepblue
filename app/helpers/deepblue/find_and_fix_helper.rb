# frozen_string_literal: true

module Deepblue

  module FindAndFixHelper

    mattr_accessor :find_and_fix_helper_debug_verbose, default: false

    def self.fix_file_sizes( id: nil,
                             curation_concern: nil,
                             task: false,
                             verbose: false,
                             fixer: nil,
                             msg_handler: nil,
                             debug_verbose: find_and_fix_helper_debug_verbose )

      debug_verbose = debug_verbose || find_and_fix_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "w.present? #{w.present?}" )
      selected = w.file_sets.select { |f| f.file_size.blank? }
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "selected.size = #{selected.size}" )
      selected.each { |f| puts f.original_file.size } if task && verbose
      selected.each { |f| f.file_size = Array(f.original_file.size); f.save }
      selected.each { |f| f.reload };true
      selected.each { |f| puts Array(f.file_size) } if task && verbose
      w.reload
      sizes = w.file_sets.map { |f| f.file_size }
      if sizes.include? []
        selected.each do |f|
          force_update_to_file_size( file_set: f,
                                     task: task,
                                     fixer: fixer,
                                     verbose: verbose,
                                     debug_verbose: debug_verbose ) if f.file_size.blank?
        end
      end
      w.reload
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "file_sets.map { |f| f.file_size } = #{sizes}" )
      solr_reindex_work_with_total_size_update( id: w.id, fixer: fixer, task: task, verbose: verbose )
    end

    def self.force_update_to_file_size( file_set:,
                                        task: false,
                                        verbose: false,
                                        fixer: nil,
                                        debug_verbose: find_and_fix_helper_debug_verbose )

      debug_verbose = debug_verbose || find_and_fix_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "forcing file size update to file set: #{file_set.id}" )
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
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "#{uri_metadata}" )
      sparql_update = sparql_update_template.sub( 'NEW_METADATA', file_set.original_file.size.to_s )
      rv = ActiveFedora.fedora.connection.patch( uri_metadata,
                                                 sparql_update,
                                                 "Content-Type" => "application/sparql-update" )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "Updated file size returned status #{rv.status}" )
      file_set.date_modified = DateTime.now
      file_set.save!( validate: false )
      # file_set.parent.update_total_file_size!
      true
    end

    def self.solr_reindex_work_with_total_size_update( id: nil,
                                                       curation_concern: nil,
                                                       fixer: nil,
                                                       task: false,
                                                       verbose: false,
                                                       debug_verbose: find_and_fix_helper_debug_verbose )

      debug_verbose = debug_verbose || find_and_fix_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "w.present? #{w.present?}" )
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
    def self.valid_file_sizes?( id: nil,
                                curation_concern: nil,
                                fixer: nil,
                                check_solr: true,
                                task: false,
                                verbose: false,
                                debug_verbose: find_and_fix_helper_debug_verbose )

      debug_verbose = debug_verbose || find_and_fix_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "w.present? #{w.present?}" )
      sizes = w.file_sets.map { |f| f.file_size }
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "file_sets.map { |f| f.file_size } = #{sizes}" )
      return false if sizes.include? []
      return true unless check_solr
      sizes = w.file_sets.map { |f| doc = ::SolrDocument.find f.id; doc['file_size_lts'] }
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "file_sets.map of solr docs = #{sizes}" )
      return true
    end

    def self.valid_ordered_members?( id: nil,
                                     curation_concern: nil,
                                     task: false,
                                     verbose: false,
                                     debug_verbose: find_and_fix_helper_debug_verbose )

      debug_verbose = debug_verbose || find_and_fix_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.present?=#{curation_concern.present?}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "w.present? #{w.present?}" )
      return false unless w.present?
      a = Array(w.ordered_members)
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "ordered_members.include? nil = #{a.include? nil}" )
      return false if a.include? nil
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "ordered_members.size = #{a.size}" )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "file_sets.size = #{w.file_sets.size}" )
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "file_sets.size == a.size = #{w.file_sets.size == a.size}" )
      return false if w.file_sets.size == a.size
      selected = w.file_sets.select { |f| f.file_size.blank? }
      puts_msg( fixer: fixer, task: task, verbose: verbose, msg: "selected.size = #{selected.size}" )
      return true unless task && verbose
      selected.each do |f|
        puts_msg( fixer: fixer, task: task, verbose: verbose, msg: f.original_file.size )
      end
      return true
    end

    def self.puts_msg( msg:, fixer:, verbose:, task: )
      return unless verbose
      fixer.add_msg msg if fixer.present? && !task
      puts msg if task
    end

  end

end
