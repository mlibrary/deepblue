# frozen_string_literal: true

module FindAndFixEmptyFileSizesBehavior

  mattr_accessor :find_and_fix_empty_file_sizes_debug_verbose, default: false

  def find_and_fix_empty_file_sizes( messages:, ids_fixed: [], filter:, test_mode: false, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "filter.class.name=#{filter.class.name}",
                                           "" ] if find_and_fix_empty_file_sizes_debug_verbose
    messages << "Started processing find_and_fix_empty_file_sizes at #{DateTime.now}"

    sparql_template=<<-END_OF_SPARQL_TEMPLATE
PREFIX ebucore: <http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#>
INSERT {
  <> ebucore:fileSize "NEW_METADATA" .
}
WHERE { }
END_OF_SPARQL_TEMPLATE

    FileSet.all.each do |file_set|
      curation_concern = file_set.parent
      if curation_concern.nil?
        messages << "#{file_set.id} parent is nil"
        next
      end
      if filter.present? && curation_concern.date_modified.present?
        next unless filter.include?( curation_concern.date_modified )
      end
      if file_set.files.empty?
        messages << "#{file_set.id} files is empty"
        next
      end
      if file_set.file_size.empty?
        found = nil
        file_set.files.each do |f|
          if f.file_size.empty?
            found = f
            break
          end
        end
        if found.present?
          original_file_size = file_set.original_file.size.to_s
          messages << "File set #{file_set.id} forcing file size update to #{original_file_size}." if verbose
          unless test_mode
            uri = found.uri.value
            uri_metadata = "#{uri}/fcr:metadata"
            sparql_update = sparql_template.sub( 'NEW_METADATA', original_file_size )
            rv = ActiveFedora.fedora.connection.patch( uri_metadata,
                                                       sparql_update,
                                                       "Content-Type" => "application/sparql-update" )
            messages << "Updated file size returned status #{rv.status}" if verbose
            # file_set.date_modified = DateTime.now
            # file_set.save!( validate: false )
            # curation_concern.update_total_file_size!
            ids_fixed << file_set.id
          end
        else
          messages << "Skipping file size update to file set: #{file_set.id} because file set file not found."
        end
      end
    end

    ids_fixed.each do |fs_id|
      fs = FileSet.find fs_id
      unless test_mode
        fs.date_modified = DateTime.now
        fs.save!( validate: false )
        fs.parent.update_total_file_size!
      end
      messages << "FileSet #{fs_id} parent work #{fs.parent.id} updating total file size." if verbose
    end

    messages << "FileSet ids found and fixed: #{ids_fixed}" unless ids_fixed.empty?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if find_and_fix_empty_file_sizes_debug_verbose
    messages << "Finished processing find_and_fix_empty_file_sizes at #{DateTime.now}"
  end

end
