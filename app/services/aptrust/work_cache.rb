# frozen_string_literal: true

require_relative './aptrust'
require_relative '../../models/aptrust/status'

class Aptrust::WorkCache

  attr_accessor :noid
  attr_accessor :work
  attr_accessor :solr
  attr_accessor :msg_handler

  def initialize( noid: nil, work: nil, solr: true, msg_handler: nil )
    @noid = noid
    @work = work
    @solr = solr
    @msg_handler = msg_handler
    @date_modified = nil
  end

  def date_modified
    if @solr
      rv = date_modified_solr
    else
      rv = work.date_modified
    end
    return rv
  end

  def date_modified_solr
    @date_modified ||= date_modified_solr_init
  end

  def date_modified_solr_init
    rv = work['date_modified_dtsi']
    rv = DateTime.parse rv
    return rv
  end

  def file_set_ids
    if @solr
      rv = work['file_set_ids_ssim']
    else
      rv = work.file_set_ids
    end
    return rv
  end

  def id
    if @solr
      rv = work['id']
    else
      rv = work.id
    end
    return rv
  end

  def published?
    if @solr
      rv = published_solr?
    else
      rv = work.published?
    end
    return rv
  end

  def published_solr?
    doc = work
    return false unless doc['visibility_ssi'] == 'open'
    return false unless doc['workflow_state_name_ssim'] = ["deposited"]
    return false if doc['suppressed_bsi']
    return true
  end

  def reset
    @noid = nil
    @work = nil
    @date_modified = nil
    return self
  end

  def total_file_size
    if @solr
      rv = work['total_file_size_lts']
    else
      rv = work.total_file_size
    end
    return rv
  end

  def work
    @work ||= work_init
  end

  def work_init
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

  def work_present?
    work.present?
  end

end
