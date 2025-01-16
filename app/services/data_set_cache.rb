# frozen_string_literal: true

# TODO: move to models?

class DataSetCache

  attr_accessor :noid
  attr_accessor :data_set
  attr_accessor :solr
  attr_accessor :msg_handler

  def initialize( noid: nil, data_set: nil, solr: true, msg_handler: nil )
    @noid = noid
    @data_set = data_set
    @solr = solr
    @msg_handler = msg_handler
    @date_modified = nil
  end

  def data_set
    @data_set ||= data_set_init
  end

  def find_solr( noid: )
    ::PersistHelper.find_solr( noid, fail_if_not_found: false )
  end

  def data_set_init
    rv = nil
    begin
      if @solr.present?
        rv = find_solr( noid: @noid )
        msg_handler.msg_warn( "Solr query failed to find id: #{noid}" ) if msg_handler.present? && rv.nil?
      end
    end
    if rv.nil?
      rv = PersistHelper.find_or_nil @noid
      msg_handler.msg_warn( "Fedora query failed to find id: #{noid}" ) if  msg_handler.present? && rv.nil?
    end
    return rv
  end

  def data_set_present?
    data_set.present?
  end

  def date_modified
    if @solr.present?
      rv = date_modified_solr
    else
      rv = data_set.date_modified
    end
    return rv
  end

  def date_modified_solr
    @date_modified ||= date_modified_solr_init
  end

  def date_modified_solr_init
    rv = @solr['date_modified_dtsi']
    rv = DateTime.parse rv
    return rv
  end

  def draft?
    if @solr.present?
      rv = draft_solr?
    else
      rv = data_set.draft_mode?
    end
    return rv
  end

  def draft_solr?
    doc = data_set
    return ::Deepblue::DraftAdminSetService.draft_admin_set_title == doc["admin_set_tesim"][0]
  end

  def file_set_ids
    if @solr.present?
      rv = @solr['file_set_ids_ssim']
    else
      rv = data_set.file_set_ids
    end
    return rv
  end

  def id
    if @solr.present?
      rv = @solr['id']
    else
      rv = data_set.id
    end
    return rv
  end

  def published?
    if @solr.present?
      rv = published_solr?
    else
      rv = data_set.published?
    end
    return rv
  end

  def published_solr?
    return false unless @solr['visibility_ssi'] == 'open'
    return false unless @solr['workflow_state_name_ssim'] = ["deposited"]
    return false if @solr['suppressed_bsi']
    return true
  end

  def reset
    @noid = nil
    @data_set = nil
    @date_modified = nil
    @solr = nil
    return self
  end

  def reset_with( noid_or_data_set_or_solr_doc )
    reset
    if noid_or_data_set_or_solr_doc.is_a? String
      @noid = noid_or_data_set_or_solr_doc
      @solr = find_solr( noid: @noid )
      @data_set = ::PersistHelper.find_or_nil( @noid ) if @solr.nil?
    elsif noid_or_data_set_or_solr_doc.is_a? DataSet
      @noid = noid_or_data_set_or_solr_doc.id
      @data_set = noid_or_data_set_or_solr_doc
    else
      @noid = noid_or_data_set_or_solr_doc['id']
      @solr = noid_or_data_set_or_solr_doc
    end
    return self
  end

  def solr_present?
    @solr.present?
  end

  def total_file_size
    if @solr.present?
      rv = @solr['total_file_size_lts']
    else
      rv = data_set.total_file_size
    end
    rv = 0 if rv.nil?
    return rv
  end

end
