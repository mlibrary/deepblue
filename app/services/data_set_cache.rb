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

  def date_modified
    if @solr
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
    rv = data_set['date_modified_dtsi']
    rv = DateTime.parse rv
    return rv
  end

  def file_set_ids
    if @solr
      rv = data_set['file_set_ids_ssim']
    else
      rv = data_set.file_set_ids
    end
    return rv
  end

  def id
    if @solr
      rv = data_set['id']
    else
      rv = data_set.id
    end
    return rv
  end

  def published?
    if @solr
      rv = published_solr?
    else
      rv = data_set.published?
    end
    return rv
  end

  def published_solr?
    doc = data_set
    return false unless doc['visibility_ssi'] == 'open'
    return false unless doc['workflow_state_name_ssim'] = ["deposited"]
    return false if doc['suppressed_bsi']
    return true
  end

  def reset
    @noid = nil
    @data_set = nil
    @date_modified = nil
    return self
  end

  def total_file_size
    if @solr
      rv = data_set['total_file_size_lts']
    else
      rv = data_set.total_file_size
    end
    return rv
  end

  def data_set
    @data_set ||= data_set_init
  end

  def data_set_init
    rv = nil
    begin
      if @solr
        rv = ActiveFedora::SolrService.query("id:#{noid}", rows: 1)
        rv = rv.first
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

end
