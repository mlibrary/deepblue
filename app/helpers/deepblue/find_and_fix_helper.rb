# frozen_string_literal: true

module Deepblue

  module FindAndFixHelper

    mattr_accessor :find_and_fix_helper_debug_verbose, default: false

    def self.duration( label: nil, msg_handler: nil, ignore_seconds: false, ignore_millis: true )
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      dur = duration_millis_as_arr( (t1 - t0) * 1000, ignore_seconds: ignore_seconds, ignore_millis: ignore_millis )
      if msg_handler.present?
        label ||= 'Duration: '
        msg_handler.msg "#{label}#{dur.join(' ')}"
      else
        return dur
      end
    end

    def self.duration_millis_as_arr( millis, ignore_seconds: false, ignore_millis: false )
      millis = millis.truncate
      secs,  millis = millis.divmod(1000)
      mins,  secs   = secs.divmod(60)
      hours, mins   = mins.divmod(60)
      days,  hours  = hours.divmod(24)
      rv = []
      loop do # just to use breaks
        rv << "#{days} #{1 == days ? 'day' : 'days'}" if days > 0
        rv << "#{hours} #{1 == hours ? 'hour' : 'hours'}" if hours > 0 || rv.present?
        rv << "#{mins} #{1 == mins ? 'minute' : 'minutes'}" if mins > 0 || rv.present?
        break if ignore_seconds
        rv << "#{secs} #{1 == secs ? 'second' : 'seconds'}" if secs > 0 || rv.present?
        break if ignore_millis
        rv << "#{millis} #{1 == millis ? 'millisecond' : 'milliseconds'}" if millis > 0 || rv.present?
        break # always break at the end
      end
      return rv
    end

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
      selected ||= []
      msg_handler.msg_verbose "selected.size = #{selected.size}"
      selected.each { |f| msg_handler.msg_verbose f.original_file_size } if msg_handler.to_console
      selected.each { |f| f.file_size = Array(f.original_file_size); f.save(validate: false) }
      selected.each { |f| f.reload }
      selected.each { |f| msg_handler.msg_verbose Array(f.file_size) }
      w.reload
      sizes = w.file_sets.map { |f| f.file_size }
      sizes ||= []
      if sizes.include? []
        selected.each do |f|
          force_update_to_file_size( file_set: f, msg_handler: msg_handler ) if f.file_size.blank?
        end
      end
      w.reload
      # msg_handler.msg_verbose "file_sets.map { |f| f.file_size } = #{sizes}"
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
      if file_set.original_file.nil?
        msg_handler.msg_verbose "Can't update file set #{file_set&.id} because original_file is nil."
        return false
      end
      size = file_set.original_file.size
      sparql_update = sparql_update_template.sub( 'NEW_METADATA', size.to_s )
      rv = ActiveFedora.fedora.connection.patch( uri_metadata,
                                                 sparql_update,
                                                 "Content-Type" => "application/sparql-update" )
      msg_handler.msg_verbose "Updated file size returned status #{rv.status}"
      # file_set.date_modified = DateTime.now
      # file_set.save!( validate: false )
      file_set.metadata_touch( validate: false )
      buf = []
      buf << file_set.to_solr
      ActiveFedora::SolrService.add( buf, softCommit: true )
      ActiveFedora::SolrService.commit
      # file_set.parent.update_total_file_size!
      true
    end

    def self.resolve_curation_concern( id: nil, curation_concern: nil )
      return curation_concern if curation_concern.present?
      ::PersistHelper.find id
    end

    def self.resolve_curation_concern_solr( id: nil, curation_concern: nil )
      id = curation_concern.id if id.blank? && curation_concern.present?
      SolrDocument.find id
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

    def self.valid_file_sizes?( id: nil, curation_concern: nil, check_solr: true, msg_handler: )
      debug_verbose = msg_handler.debug_verbose || find_and_fix_helper_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "check_solr=#{check_solr}",
                               "curation_concern.present?=#{curation_concern.present?}",
                               "" ] if debug_verbose
      w = resolve_curation_concern( id: id, curation_concern: curation_concern )
      msg_handler.msg_verbose "w.present? #{w.present?}"
      return false unless valid_file_set_model_sizes?( work: w, msg_handler: msg_handler )
      return true unless check_solr
      return valid_file_set_solr_sizes?( work: w, msg_handler: msg_handler )
    end

    def self.valid_file_set_model_sizes?( work:, msg_handler: )
      work.file_sets.each do |f|
        a = Array(f.file_size)
        if a.empty?
          return false
        else
          size = a.first.to_i
          return false if 0 == size
        end
      end
      return true
    end

    def self.valid_file_set_solr_sizes?( work:, msg_handler: )
      work.file_sets.map.each do |f|
        doc = PersistHelper.find_solr( f.id, fail_if_not_found: false )
        return false if doc.blank?
        return false if 0 == doc['file_size_lts']
      end
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
