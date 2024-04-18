# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/services/aptrust/aptrust_upload_work'
require_relative '../../../app/services/aptrust/aptrust_uploader'
require_relative '../../../app/services/aptrust/aptrust_uploader_for_work'

module Aptrust

  class WorkCache

    attr_accessor :noid
    attr_accessor :work
    attr_accessor :solr

    def initialize( noid: nil, work: nil, solr: true )
      @noid = noid
      @work = work
      @solr = solr
      @date_modified = nil
    end

    def reset
      @noid = nil
      @work = nil
      @date_modified = nil
      return self
    end

    def work
      @work ||= work_init
    end

    def work_init
      if @solr
        rv = ActiveFedora::SolrService.query("id:#{noid}", rows: 1)
        rv = rv.first
      else
        rv = PersistHelper.find @noid
      end
      return rv
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

    def total_file_size
      if @solr
        rv = work['total_file_size_lts']
      else
        rv = work.total_file_size
      end
      return rv
    end

  end

  class AbstractUploadTask < ::Aptrust::AbstractTask

    attr_accessor :bag_max_total_file_size # TODO
    attr_accessor :cleanup_after_deposit
    attr_accessor :cleanup_bag
    attr_accessor :cleanup_bag_data
    attr_accessor :debug_assume_upload_succeeds
    attr_accessor :max_size
    attr_accessor :max_uploads
    attr_accessor :noid_pairs
    attr_accessor :sleep_secs
    attr_accessor :sort

    attr_accessor :zip_data_dir


    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @cleanup_after_deposit = option_value( key: 'cleanup_after_deposit', default_value: true )
      @cleanup_bag = option_value( key: 'cleanup_bag', default_value: true )
      @cleanup_bag_data = option_value( key: 'cleanup_bag_data', default_value: true )
      @debug_assume_upload_succeeds = option_value( key: 'debug_assume_upload_succeeds', default_value: false )
      @sleep_secs = option_sleep_secs
      @sort = option_value( key: 'sort', default_value: false )
      @zip_data_dir = option_value( key: 'zip_data_dir', default_value: false )
    end

    def noid_pairs
      @noid_pairs ||= noid_pairs_init
    end

    def noid_pairs_init
      noids_sort
    end

    def noids_sort
      putsf "Sorting noids into noid_pairs" if verbose
      @noid_pairs=[]
      return unless sort?
      return unless noids.present?
      w = WorkCache.new
      noids.each { |noid| w.reset.noid = noid; @noid_pairs << { noid: noid, size: w.total_file_size } }
      @noid_pairs.sort! { |a,b| a[:size] < b[:size] ? 0 : 1 }
      # @noid_pairs = @noid_pairs.select { |p| p[:size] <= max_size } if 0 < max_size
    end

    def option_max_size
      opt = task_options_value( key: 'max_size', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      # opt = opt.to_i if opt.is_a? String
      opt = to_integer( num: opt ) if opt.is_a? String
      putsf "max_size='#{opt}'" if verbose
      return opt
    end

    def option_max_uploads
      opt = task_options_value( key: 'max_uploads', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      putsf "max_uploads='#{opt}'" if verbose
      return opt
    end

    def option_sleep_secs
      opt = task_options_value( key: 'sleep_secs', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      putsf "sleep_secs=#{opt}" if verbose
      return opt
    end

    def run_upload( noid:, size: nil )
      putsf "sleeping for #{sleep_secs}" if 0 < sleep_secs
      sleep( sleep_secs ) if 0 < sleep_secs
      msg = "Uploading: #{noid}"
      msg += " - #{readable_sz(size)}" if size.present?
      putsf msg
      ::Aptrust::AptrustIntegrationService.dump_mattrs.each {|mattr| putsf mattr } if debug_verbose
      msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true,
                                                                verbose: verbose,
                                                                debug_verbose: debug_verbose )
      uploader = ::Aptrust::AptrustUploadWork.new( msg_handler: msg_handler, debug_verbose: debug_verbose,
                                                   # bag_max_total_file_size: 300.megabytes,
                                                   cleanup_after_deposit: cleanup_after_deposit,
                                                   cleanup_bag: cleanup_bag,
                                                   cleanup_bag_data: cleanup_bag_data,
                                                   debug_assume_upload_succeeds: debug_assume_upload_succeeds,
                                                   noid: noid,
                                                   zip_data_dir: zip_data_dir )
      @export_dir = File.absolute_path @export_dir if @export_dir.present?
      @working_dir = File.absolute_path @working_dir if @working_dir.present?
      uploader.export_dir = @export_dir if @export_dir.present?
      uploader.working_dir = @working_dir if @working_dir.present?

      # putsf "uploader=#{uploader.pretty_inspect}"
      putsf "test_mode?=#{test_mode?}"  if verbose
      return if test_mode?
      uploader.run
    end

    def sort?
      @sort
    end

    def w_all( solr: true )
      if solr
        rv = ActiveFedora::SolrService.query("+(has_model_ssim:DataSet)", rows: 100_000)
      else
        rv = DataSet.all
      end
      return rv
    end

  end

end
