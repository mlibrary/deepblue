# frozen_string_literal: true

module FindAndFixEmptyFileSizesBehavior

  mattr_accessor :find_and_fix_empty_file_sizes_debug_verbose,
                 default: ::Deepblue::FindAndFixService.find_and_fix_empty_file_sizes_debug_verbose


  SPARQL_TEMPLATE=<<-END_OF_SPARQL_TEMPLATE
PREFIX ebucore: <http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#>
INSERT {
  <> ebucore:fileSize "NEW_METADATA" .
}
WHERE { }
  END_OF_SPARQL_TEMPLATE

  attr_accessor :messages, :ids_fixed, :filter, :test_mode, :verbose
  attr_accessor :fs_ids_updated, :fs_ids_solr_mismatch

  def filter_out?( file_set: )
    return false unless filter.present?
    return false unless file_set.date_modified.present?
    return filter.include?( file_set.date_modified )
  end

  def file_size_solr_mismatch?( file_set: )
    solr_doc = ::SolrDocument.find file_set.id
    return file_set.file_size != Array(solr_doc[:file_size_lts].to_s)
  end

  def find_and_fix_empty_file_sizes( messages:, ids_fixed: [], filter:, test_mode: false, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "filter.class.name=#{filter.class.name}",
                                           "" ] if find_and_fix_empty_file_sizes_debug_verbose
    @messages = messages
    @ids_fixed = ids_fixed
    @filter = filter
    @test_mode = test_mode
    @verbose = verbose
    @fs_ids_updated = []
    @fs_ids_solr_mismatch = []
    find_and_fix_empty_file_sizes_run
  end

  def find_and_fix_empty_file_size_run
    messages << "Started processing find_and_fix_empty_file_sizes at #{DateTime.now}"
    FileSet.all.each do |file_set|
      curation_concern = file_set.parent
      if curation_concern.nil?
        messages << "#{file_set.id} parent is nil"
        # skip
      elsif filter_out?( file_set: file_set )
        # skip
      elsif needs_file_size_update?( file_set: file_set )
        force_update_to_file_size( file_set: file_set )
      elsif file_size_solr_mismatch?( file_set: file_set )
        fs_ids_solr_mismatch << file_set_id unless test_mode
      end
    end
    update_work_file_sizes( file_set_ids: fs_ids_updated )
    update_work_file_sizes( file_set_ids: fs_ids_solr_mismatch )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if find_and_fix_empty_file_sizes_debug_verbose
    messages << "Finished processing find_and_fix_empty_file_sizes at #{DateTime.now}"
  end

  def force_update_to_file_size( file_set: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "" ] if find_and_fix_empty_file_sizes_debug_verbose

    found = nil
    file_set.files.each do |f|
      if f.file_size.empty?
        found = f
        break
      end
    end
    messages << "Skipping file size update to file set: #{file_set.id} because file set file not found." unless found
    return unless found
    original_file_size = file_set.original_file.size.to_s
    messages << "File set #{file_set.id} forcing file size update to #{original_file_size}." if verbose
    unless test_mode
      uri = found.uri.value
      uri_metadata = "#{uri}/fcr:metadata"
      sparql_update = SPARQL_TEMPLATE.sub( 'NEW_METADATA', original_file_size )
      rv = ActiveFedora.fedora.connection.patch( uri_metadata,
                                                 sparql_update,
                                                 "Content-Type" => "application/sparql-update" )
      messages << "Updated file size returned status #{rv.status}" if verbose
      fs_ids_updated << file_set.id
    end
  end

  def needs_file_size_update?( file_set: )
    if file_set.files.empty?
      messages << "#{file_set.id} files is empty"
      return false
    end
    return true
  end

  def update_work_file_sizes( file_set_ids: )
    return if file_set_ids.empty?
    file_set_ids.each do |fs_id|
      fs = FileSet.find fs_id
      batch = []
      unless test_mode
        fs.date_modified = DateTime.now
        fs.save!( validate: false )
        batch << fs.to_solr
        if batch.size >= 5
          ActiveFedora::SolrService.add(batch, softCommit: true)
          ActiveFedora::SolrService.commit
          batch = []
        end
      end
      if batch.size > 0
        ActiveFedora::SolrService.add(batch, softCommit: true)
        ActiveFedora::SolrService.commit
      end
      messages << "FileSet #{fs_id} parent work #{fs.parent.id} updating total file size." if verbose
    end
    file_sets.each do |fs_id|
      fs = FileSet.find( fs_id )
      fs.parent&.update_total_file_size! unless test_mode
      messages << "FileSet #{fs_id} parent work #{fs.parent.id} updating total file size." if verbose
    end
    file_set_ids.each { |fid| ids_fixed << fid }
  end

end
