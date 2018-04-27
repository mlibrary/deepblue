module MetadataHelper

  @@FIELD_SEP = '; '.freeze

  def self.human_readable_size( value )
    value = value.to_i
    return ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
  end

  def self.metadata_filename_collection( pathname_dir, collection )
    pathname_dir.join "w_#{collection.id}_metadata_report.txt"
  end

  def self.metadata_filename_collection_work( pathname_dir, collection, work )
    pathname_dir.join "c_#{collection.id}_w_#{work.id}_metadata_report.txt"
  end

  def self.metadata_filename_work( pathname_dir, work )
    pathname_dir.join "w_#{work.id}_metadata_report.txt"
  end

  def self.ordered( ordered_values: nil, values: nil )
    return nil if values.nil?
    if DeepBlueDocs::Application.config.do_ordered_list_hack
      unless ordered_values.nil?
        begin
          values = OrderedStringHelper.deserialize( ordered_values )
        rescue OrderedStringHelper::DeserializeError
          # fallback to original values, which are stored in an unspecified order
          return values
        end
      end
    end
    return values
  end

  def self.ordered_values( ordered_values: nil, values: nil )
    return nil if values.nil?
    rv = nil
    if DeepBlueDocs::Application.config.do_ordered_list_hack
      if DeepBlueDocs::Application.config.do_ordered_list_hack_save
        rv = OrderedStringHelper.serialize( values )
      elsif !ordered_values.nil?
        rv = OrderedStringHelper.serialize( values )
      end
    end
    return rv
  end

  def self.report_collection( collection, dir: nil, out: nil, depth:  '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_collection( dir, collection )
      open( target_file, 'w' ) do |out|
        report_collection( collection, out: out, depth: depth )
      end
    else
      title = title( collection, field_sep:'' );
      out.puts "#{depth} Collection: #{title} #{depth}"
      report_item( out, "ID: ", collection.id )
      report_item( out, "Title: ", collection.title, one_line: true )
      report_item( out, "Total items: ", collection.member_objects.count )
      report_item( out, "Total size: ", human_readable_size( collection.bytes ) )
      report_item( out, "Creator: ", collection.creator, one_line: false, item_prefix: "\t" )
      report_item( out, "Keyword: ", collection.keyword, one_line: false, item_prefix: "\t" )
      report_item( out, "Discipline: ", collection.subject, one_line: false, item_prefix: "\t" )
      report_item( out, "Language: ", collection.language )
      report_item( out, "Citation to related material: ", collection.isReferencedBy )
      report_item( out, "Visibility: ", collection.visibility )
      if 0 < collection.member_objects.count
        collection.member_objects.each do |generic_work|
          out.puts
          report_generic_work( generic_work, out: out, depth: "=#{depth}" )
        end
      end
    end
    return target_file
  end

  def self.report_collection_work( collection, generic_work, dir: nil, out: nil, depth:  '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_collection_work( dir, collection, generic_work )
      open( target_file, 'w' ) do |out|
        report_collection_work( collection, generic_work, out: out, depth: depth )
      end
    else
      report_work( generic_work, out: out, depth: depth )
    end
    return target_file
  end

  def self.report_file_set( file_set, out: nil, depth:  '==' )
    out.puts "#{depth} File Set: #{file_set.label} #{depth}"
    report_item( out, "ID: ", file_set.id )
    report_item( out, "File name: ", file_set.label )
    report_item( out, "Date uploaded: ", file_set.date_uploaded )
    report_item( out, "Date modified: ", file_set.date_uploaded )
    report_item( out, "Total file size: ", human_readable_size( file_set.file_size[0] ) )
    report_item( out, "Checksum: ", file_set.original_checksum )
    report_item( out, "Mimetype: ", file_set.mime_type )
  end

  def self.report_generic_work( generic_work, dir: nil, out: nil, depth: '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_work( dir, generic_work )
      open( target_file, 'w' ) do |out|
        report_generic_work( generic_work, out: out, depth: depth )
      end
    else
      title = title( generic_work, field_sep:'' );
      out.puts "#{depth} Generic Work: #{title} #{depth}"
      report_item( out, "ID: ", generic_work.id )
      report_item( out, "Title: ", generic_work.title, one_line: true )
      report_item( out, "Methodology: ", generic_work.methodology )
      report_item( out, "Description: ", generic_work.description, one_line: false, item_prefix: "\t" )
      report_item( out, "Creator: ", generic_work.creator, one_line: false, item_prefix: "\t" )
      report_item( out, "Depositor: ", generic_work.depositor )
      report_item( out, "Contact: ", generic_work.authoremail )
      report_item( out, "Discipline: ", generic_work.subject, one_line: false, item_prefix: "\t" )
      report_item( out, "Funded by: ", generic_work.fundedby )
      report_item( out, "ORSP Grant Number: ", generic_work.grantnumber )
      report_item( out, "Keyword: ", generic_work.keyword, one_line: false, item_prefix: "\t" )
      report_item( out, "Date coverage: ", generic_work.date_coverage )
      report_item( out, "Citation to related material: ", generic_work.isReferencedBy )
      report_item( out, "Language: ", generic_work.language )
      report_item( out, "Total file count: ", generic_work.file_set_ids.count )
      report_item( out, "Total file size: ", human_readable_size( generic_work.total_file_size ) )
      report_item( out, "DOI: ", generic_work.doi, optional: true )
      report_item( out, "Visibility: ", generic_work.visibility )
      report_item( out, "Rights: ", generic_work.rights )
      report_item( out, "Admin set id: ", generic_work.admin_set_id )
      report_item( out, "Tombstone: ", generic_work.tombstone, optional: true )
      if 0 < generic_work.file_sets.count
        generic_work.file_sets.each do |file_set|
          out.puts
          report_file_set( file_set, out: out, depth: "=#{depth}" )
        end
      end
    end
    return target_file
  end

  def self.report_item( out,
                        label,
                        value,
                        item_prefix: '',
                        item_postfix: '',
                        item_seperator: @@FIELD_SEP,
                        one_line: nil,
                        optional: false
                      )
    multi_item = value.respond_to?( :count ) && value.respond_to?( :each )
    if optional
      return if value.nil?
      return if value.to_s.empty?
      return if multi_item && 0 == value.count
    end
    if one_line.nil?
      one_line = true
      if multi_item
        if 1 < value.count
          one_line = false
        end
      end
    end
    if one_line
      if value.respond_to?( :join )
        out.puts( "#{label}#{item_prefix}#{value.join( "#{item_prefix}#{item_seperator}#{item_postfix}" )}#{item_postfix}" )
      elsif multi_item
        out.print( "#{label}" )
        count = 0
        value.each do |item|
          count += 1
          out.print( "#{item_prefix}#{item}#{item_postfix}" )
          out.print( "#{item_seperator}" ) unless value.count == count
        end
        out.puts
      else
        out.puts( "#{label}#{item_prefix}#{value}#{item_postfix}" )
      end
    else
      out.puts( "#{label}" )
      if multi_item
        value.each { |item| out.puts( "#{item_prefix}#{item}#{item_postfix}" ) }
      else
        out.puts( "#{item_prefix}#{value}#{item_postfix}" )
      end
    end
  end

  def self.title( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.title.join( field_sep )
  end


end
