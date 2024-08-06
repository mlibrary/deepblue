# frozen_string_literal: true

module Deepblue

  module CurationConcernReportBehavior

    DEFAULT_FILE_EXT_RE = Regexp.compile( '^.+\.([^\.]+)$' ).freeze unless const_defined? :DEFAULT_FILE_EXT_RE

    DEFAULT_REPORT_DIR = "." unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX

    VISIBILITY_KEYS = [ Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE ] unless const_defined? :VISIBILITY_KEYS

    attr_accessor :file_ext_re
    attr_accessor :collections_file, :works_file, :file_sets_file
    attr_accessor :collection_size, :work_size
    attr_accessor :msg_handler
    attr_accessor :out_report
    attr_accessor :out_collections, :out_works, :out_file_sets, :prefix
    attr_accessor :report_dir
    attr_accessor :report_timestamp_begin, :report_timestamp_end
    attr_accessor :tagged_totals
    attr_accessor :totals
    attr_accessor :work_ids_reported, :work_file_count_cache, :work_size_cache

    def initialize_report_values
      @totals = Hash.new( 0 )
      @tagged_totals = {}
      @work_ids_reported = {}
      @work_file_count_cache = {}
      @work_size_cache = {}
      @out_report = StringIO.new
    end

    def collection_file_set_count_and_size( collection_work_ids: )
      file_set_count = 0
      total_size = 0
      collection_work_ids.each do |id|
        w = ::PersistHelper.find id
        next unless w.respond_to? :file_sets
        # msg_handler.buffer 'w'
        w.file_sets do |fs|
          # msg_handler.buffer 'f'
          file_set_count += 1
          total_size += size_of fs
        end
        # msg_handler.msg ''
      end
      return file_set_count, total_size
    end

    def collection_work_ids( collection: )
      c_id = collection.id
      works = TaskHelper.all_works.select { |w| w.member_of_collection_ids.include? c_id }
      return [] if works.blank?
      rv = works.map { |w| w.id } # rubocop:disable Style/SymbolProc
      return rv
    end

    def curation_concern_status( curation_concern, file_set: nil )
      if TaskHelper.dbd_version_1?
        obj = if file_set.present?
                file_set
              else
                curation_concern
              end
        if obj.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          'public'
        else
          'private'
        end
      elsif curation_concern.is_a? Collection
        if curation_concern.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          'published'
        else
          'pending_review'
        end
      else
        begin
          # hyrax2 # e = PowerConverter.convert( curation_concern, to: :sipity_entity )
          e = Sipity::Entity(curation_concern)
          if e.present? && 'deposited' == e.workflow_state_name
            'published'
          else
            'pending_review'
          end
        rescue Sipity::ConversionError => e
          @msg_handler.msg_error "Conversion to sippity entity failed for curation concern #{curation_concern.id}" if @msg_handler.present?
          'unknown'
        end
      end
    end

    def curation_concern_visibility( curation_concern, file_set: nil )
      if TaskHelper.dbd_version_1?
        obj = if file_set.present?
                file_set
              else
                curation_concern
              end
        obj.visibility
      elsif curation_concern.is_a? Collection
        curation_concern.visibility
      else
        curation_concern.visibility
      end
    end

    def expand_path_partials( path )
      ReportHelper.expand_path_partials( path )
    end

    def extension_for( af )
      return '' if af.nil?
      match = file_ext_re.match( af.label )
      return '' unless match
      ext = match[1]
      ext = ext.downcase
      return ext
    end

    def files( count )
      if 1 == count
        '1 file'
      else
        "#{count} files"
      end
    end

    def human_readable( value )
      ActiveSupport::NumberHelper.number_to_human_size( value )
    end

    def inc( key:, by: 1 )
      x = @totals[key] + by
      @totals[key] = x
    end

    def inc_author( work )
      inc_tagged_total( base_tag: 'authors', curation_concern: work, item: work.authoremail )
    end

    def inc_collections( collection )
      inc_total( base_key: 'collections', curation_concern: collection )
    end

    def inc_collections_size( collection, size )
      inc_total_size( base_key: 'collections', curation_concern: collection, by: size )
    end

    def inc_depositor( work )
      inc_tagged_total( base_tag: 'depositors', curation_concern: work, item: work.depositor )
    end

    def inc_extension( work, file_set )
      ext = extension_for file_set
      return ext if ext.blank?
      return inc_tagged_total( base_tag: 'extensions', curation_concern: work, file_set: file_set, item: ext )
    end

    def inc_file_sets( work, _file_set )
      inc_total( base_key: 'file_sets', curation_concern: work )
    end

    def inc_tagged( tag:, item:, by: 1 )
      hash = @tagged_totals[tag]
      if hash.nil?
        hash = Hash.new( 0 )
        @tagged_totals[tag] = hash
      end
      x = hash[item] + by
      hash[item] = x # rubocop:disable Lint/UselessSetterCall
    end

    def inc_tagged_total( base_tag:, curation_concern:, file_set: nil, item:, by: 1 )
      inc_tagged( tag: base_tag, item: item, by: by )
      status = curation_concern_status( curation_concern, file_set: file_set )
      tag = key( base: base_tag, status: status )
      inc_tagged( tag: tag, item: item, by: by )
      visibility = curation_concern_visibility( curation_concern, file_set: file_set )
      tag = key( base: base_tag, status: visibility )
      inc_tagged( tag: tag, item: item, by: by )
      return item
    end

    def inc_total( base_key:, curation_concern:, file_set: nil, by: 1 )
      inc( key: key( base: base_key ), by: by )
      status = curation_concern_status( curation_concern, file_set: file_set )
      key = key( base: base_key, status: status )
      inc( key: key, by: by )
      visibility = curation_concern_visibility( curation_concern, file_set: file_set )
      key = key( base: base_key, status: visibility )
      inc( key: key, by: by )
    end

    def inc_total_size( base_key:, curation_concern:, by: )
      inc_total( base_key: "#{base_key}_size", curation_concern: curation_concern, by: by )
    end

    def inc_works( work )
      inc_total( base_key: 'works', curation_concern: work )
    end

    def inc_works_size( work, size )
      inc_total_size( base_key: 'works', curation_concern: work, by: size )
    end

    def key( base:, status: nil )
      return "#{base}_#{status}" if status.present?
      base
    end

    def parent_ids( work: )
      work.member_of_collection_ids
    end

    def print_collection_line( out, collection: nil, header: false )
      if header
        out << '"' << I18n.t( "report.curation_concerns.header.collection.id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.date_created" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.date_modified" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.depositor" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.status" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.visibility" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.work_count" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.file_set_count" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.total_size" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.total_size_print" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.discipline" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.creators" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.collection.work_ids" ) << '"'
      else
        return out if collection.nil?
        out << collection.id.to_s
        out << ',' << '"' << to_date( collection.create_date ) << '"'
        out << ',' << '"' << to_date( collection.date_modified ) << '"'
        out << ',' << '"' << collection.depositor << '"'
        out << ',' << '"' << curation_concern_status( collection ) << '"'
        out << ',' << '"' << curation_concern_visibility( collection ) << '"'
        col_work_ids = collection_work_ids( collection: collection )
        out << ',' << col_work_ids.size.to_s
        # file_set_count, total_size = collection_file_set_count_and_size( collection_work_ids: col_work_ids )
        # out << ',' << file_set_count.to_s
        # out << ',' << total_size.to_s
        # out << ',' << human_readable( total_size ).to_s
        out << ',' << @collection_size.to_s
        out << ',' << @collection_files.to_s
        out << ',' << human_readable( @collection_size ).to_s
        out << ',' << '"' << collection.subject.join( '; ' ) << '"'
        out << ',' << '"' << collection.creator.join( '; ' ) << '"'
        out << ',' << '"' << col_work_ids.join( ' ' ) << '"'
      end
      out << "\n"
      out
    end

    def print_file_set_line( out, work: nil, file_set: nil, file_size: 0, file_ext: '', header: false )
      if header
        out << '"' << I18n.t( "report.curation_concerns.header.work.id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.parent_work_id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.date_modified" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.depositor" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.status" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.visibility" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.file_size" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.file_size_print" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.file_ext" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.file_name" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.thumbnail_id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.doi" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.version_count" ) << '"'
        # out << ',' << '"' << I18n.t( "report.curation_concerns.header.file_set.tombstone" ) << '"'
      else
        return out if file_set.nil?
        out << file_set.id.to_s
        out << ',' << work.id.to_s
        out << ',' << '"' << to_date( file_set.date_modified ) << '"'
        out << ',' << '"' << file_set.depositor << '"'
        out << ',' << '"' << curation_concern_status( work, file_set: file_set ) << '"'
        out << ',' << '"' << curation_concern_visibility( work, file_set: file_set ) << '"'
        out << ',' << file_size.to_s
        out << ',' << human_readable( file_size ).to_s
        out << ',' << file_ext
        out << ',' << '"' << file_set.label << '"'
        out << ',' << '"' << (file_set.thumbnail_id.nil? ? '' : file_set.thumbnail_id).to_s << '"'
        out << ',' << '"' << (file_set.doi.nil? ? '' : file_set.doi).to_s << '"'
        out << ',' << file_set.version_count
        # out << ',' << '"' << (Array(file_set.tombstone).empty? ? '' : Array(file_set.tombstone).first).to_s << '"'
      end
      out << "\n"
      out
    end

    def print_work_line( out, work: nil, work_size: 0, header: false )
      if header
        out << '"' << I18n.t( "report.curation_concerns.header.work.id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.create_date" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.date_modified" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.date_published" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.depositor" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.authoremail" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.status" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.visibility" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.file_set_count" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.work_size" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.work_size_print" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.parent_ids" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.discipline" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.creators" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.license" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.license_other" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.thumbnail_id" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.doi" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.tombstone" ) << '"'
        out << ',' << '"' << I18n.t( "report.curation_concerns.header.work.referenced_by" ) << '"'
      else
        return out if work.nil?
        out << work.id.to_s
        out << ',' << '"' << to_date( work.create_date ) << '"'
        out << ',' << '"' << to_date( work.date_modified ) << '"'
        out << ',' << '"' << to_date( work.date_published ) << '"'
        out << ',' << '"' << work.depositor << '"'
        out << ',' << '"' << work.authoremail << '"'
        out << ',' << '"' << curation_concern_status( work ) << '"'
        out << ',' << '"' << curation_concern_visibility( work ) << '"'
        out << ',' << work.file_set_ids.size.to_s
        out << ',' << work_size.to_s
        out << ',' << human_readable( work_size ).to_s
        parent_ids = parent_ids( work: work )
        out << ',' << '"' << parent_ids.join( ' ' ) << '"'
        out << ',' << '"' << TaskHelper.work_discipline( work: work ).join( '; ' ) << '"'
        out << ',' << '"' << work.creator.join( '; ' ) << '"'
        out << ',' << '"' << work.rights_license << '"'
        out << ',' << '"' << work.rights_license_other << '"'
        out << ',' << '"' << (work.thumbnail_id.nil? ? '' : work.thumbnail_id).to_s << '"'
        out << ',' << '"' << (work.doi.nil? ? '' : work.doi).to_s << '"'
        out << ',' << '"' << (Array(work.tombstone).empty? ? '' : Array(work.tombstone).first).to_s << '"'
        out << ',' << '"' << work.referenced_by.join( '; ' ) << '"'
      end
      out << "\n"
      out
    end

    def process_collection( collection:, report_line_prefix: '' )
      return if collection.blank?
      return unless collection.is_a? Collection
      inc_collections( collection )
      # TODO: collection_authors, collection_depositors
      # authors[collection.authoremail] = authors[collection.authoremail] + 1
      # depositors[collection.depositor] = depositors[collection.depositor] + 1
      @collection_size = 0
      @collection_files = 0
      work_ids = collection_work_ids( collection: collection )
      # file_set_count, _total_size = collection_file_set_count_and_size( collection_work_ids: work_ids )
      # msg_handler.msg "#{report_line_prefix}[#{collection.id}] has #{works( work_ids.count )} and #{files( file_set_count )}..."
      msg_handler.msg "#{report_line_prefix}[#{collection.id}] has #{works(work_ids.count )} ..."
      work_ids.each do |wid|
        put 'n' if wid.nil?
        next if wid.nil?
        msg_handler.buffer "[#{collection.id}] #{wid} ..."
        @work_size = 0
        if work_ids_reported.key?( wid )
          msg_handler.buffer " already reported as"
          @work_size = work_size_cache[wid]
          @work_file_count = work_file_count_cache[wid]
        else
          work = TaskHelper.work_find( id: wid )
          inc_works( work )
          inc_author( work )
          inc_depositor( work )
          process_file_sets( work: work )
          work_ids_reported[work.id] = true
          work_size_cache[work.id] = @work_size
          @work_file_count = work.file_sets.count
          work_file_count_cache[work.id] = work.file_sets.count
          print_work_line( out_works, work: work, work_size: @work_size )
        end
        @collection_files += @work_file_count
        @collection_size += @work_size
        inc_collections_size( collection, @work_size )
        msg_handler.msg " #{human_readable( @work_size )} in #{files( @work_file_count )}"
      end
      msg_handler.msg "[#{collection.id}] has total size of #{human_readable( @collection_size )} in #{files( @collection_files )}"
      msg_handler.msg ''
      print_collection_line( out_collections, collection: collection )
    end

    def process_collections
      collections = Collection.all
      msg_handler.msg "#{collections.size} collections to process..."
      count = 0
      collections.each do |collection|
        count += 1
        report_line_prefix = "#{count} of #{collections.size}: "
        process_collection( collection: collection, report_line_prefix: report_line_prefix )
      end
    end

    def process_curation_concerns(ids: )
      return if ids.blank?
      ids.each do |id|
        curation_concern = ::PersistHelper.find id
        process_collection( collection: curation_concern )
        process_work( work: curation_concern )
      end
    end

    def process_file_sets( work: )
      work.file_sets.each do |fs|
        inc_file_sets( work, fs )
        size = size_of fs
        ext = inc_extension( work, fs )
        print_file_set_line( out_file_sets, work: work, file_set: fs, file_size: size, file_ext: ext )
        @work_size += size
        inc_works_size( work, size )
      end
    end

    def process_works
      works = TaskHelper.all_works
      msg_handler.msg "#{works.size} works to process..."
      count = 0
      works.each do |work|
        count += 1
        report_line_prefix = "#{count} of #{works.size}: "
        process_work( work: work, report_line_prefix: report_line_prefix )
      end
    end

    def process_work( work:, report_line_prefix: '' )
      return if work.nil?
      return unless TaskHelper.work? work
      @work_size = 0
      msg_handler.buffer "#{report_line_prefix}#{work.id} has #{files(work.file_set_ids.size)}..."
      if work_ids_reported.key?( work.id )
        msg_handler.buffer " already reported ..."
        @work_size = work_size_cache[work.id]
        @work_file_count = work_file_count_cache[work.id]
      else
        inc_works( work )
        inc_author( work )
        inc_depositor( work )
        process_file_sets( work: work )
        work_ids_reported[work.id] = true
        work_size_cache[work.id] = @work_size
        work_file_count_cache[work.id] = work.file_sets.count
      end
      msg_handler.msg " #{human_readable( @work_size )}"
      print_work_line( out_works, work: work, work_size: @work_size )
    end

    def quote( out, str )
      out << '"' << str << '"'
      out
    end

    def report_all_totals
      statuses = if TaskHelper.dbd_version_1?
                   [ 'public', 'private' ]
                 else
                   [ 'published', 'pending_review' ]
                 end
      out_report << "\n#{statuses[0].titlecase} Totals:\n\n"
      report_total_lines( status: statuses[0] )
      report_authors( status: statuses[0] )
      report_depositors( status: statuses[0] )
      report_top_ten( status: statuses[0] )

      out_report << "\n\n#{statuses[1].titlecase} Totals:\n\n"
      report_total_lines( status: statuses[1] )
      report_authors( status: statuses[1] )
      report_depositors( status: statuses[1] )
      report_top_ten( status: statuses[1] )

      VISIBILITY_KEYS.each do |key|
        next if 0 == report_totals( status: key )
        out_report << "\n\n#{key.titlecase} Totals:\n\n"
        report_total_lines( status: key )
        report_authors( status: key )
        report_depositors( status: key )
        report_top_ten( status: key )
      end

      out_report << "\n\nGrand Totals:\n\n"
      report_total_lines
      report_authors
      report_depositors
    end

    def report_authors( status: nil )
      report_tagged_totals( base_tag: 'authors', status: status )
    end

    def report_depositors( status: nil )
      report_tagged_totals( base_tag: 'depositors', status: status )
    end

    def report_email_body
      out_report.string
    end

    def report_email_event
      subscription_service_id
    end

    def report_email_content_type
      # ::Deepblue::EmailHelper::TEXT_HTML
      nil
    end

    def report_email_results
      return if subscription_service_id.blank?
      subscribers = ::Deepblue::EmailSubscriptionService.subscribers_for( subscription_service_id: subscription_service_id )
      return if subscribers.empty?
      subscribers.each do |subscriber|
        ::Deepblue::EmailSubscriptionService.subscription_send_email( email_target: subscriber,
                                                                      content_type: report_email_content_type,
                                                                      subject: report_email_subject,
                                                                      body: report_email_body,
                                                                      event: report_email_event,
                                                                      # event_note: event_note,
                                                                      timestamp_begin: report_timestamp_begin,
                                                                      timestamp_end: report_timestamp_end,
                                                                      subscription_service_id: subscription_service_id )
      end
    end

    def report_email_subject
      self.class.name
    end

    def report_extensions( status: nil )
      report_tagged_totals( base_tag: 'extensions', status: status )
    end

    def report_finished
      report_timestamp_end = Time.new
      out_report << "Report finished: " << report_timestamp_end.to_s << "\n"

      report_all_totals
      report_top_ten

      out_report << "\n"
      out_report << "Files written:" << "\n"
      out_report << works_file << "\n"
      out_report << file_sets_file << "\n"
      out_report << "\n"

      @out_report_file = Pathname.new( report_dir ).join "#{prefix}.txt"
      File.open( @out_report_file, 'w' ) { |out| out << out_report.string }
      msg_handler.msg ''
      msg_handler.msg ''
      msg_handler.msg out_report.string
      msg_handler.msg ''
      report_email_results
    end

    def report_tagged_totals( base_tag:, status: nil )
      # out_report << "report_tagged_totals(#{base_tag},#{status})\n"
      tag_hash = tagged( base_tag: base_tag, status: status )
      # out_report << "tag_hash='#{tag_hash}'\n"
      label = status_label( status )
      out_report << "Skipping unique and repeats for #{label}#{base_tag}\n" if tag_hash.nil?
      return if tag_hash.nil?
      out_report << "Unique #{label}#{base_tag}: #{tag_hash.size}\n"
      count = 0
      tag_hash.each_pair { |_key, value| count += 1 if value > 1 }
      out_report << "Repeat #{label}#{base_tag}: #{count}\n"
    end

    def report_top_ten( status: nil )
      status_label = status_label( status )
      top = top_ten( tagged( base_tag: 'authors', status: status ) )
      top_ten_print( "\nTop ten #{status_label}authors:", top )
      top = top_ten( tagged( base_tag: 'depositors', status: status ) )
      top_ten_print( "\nTop ten #{status_label}depositors:", top )
      top = top_ten( tagged( base_tag: 'extensions', status: status ) )
      top_ten_print( "\nTop ten #{status_label}extensions:", top )
    end

    def report_total( type, status: nil )
      key = key( base: type, status: status )
      return 0 unless @totals.key? key
      total( key )
    end

    def report_total_line( type, status: nil )
      key = key( base: type, status: status )
      return unless @totals.key? key
      label = status_label( status )
      total = total( key )
      out_report << "Total #{label}#{type.humanize( capitalize: false )}: #{total}" << "\n"
    end

    def report_total_size_line( type, status: nil )
      key = key( base: "#{type}_size", status: status )
      return unless @totals.key? key
      label = status_label( status )
      total = total( key )
      out_report << "Total #{label}#{type} size: #{human_readable( total )}" << "\n"
    end

    def report_totals( status: nil )
      total = 0
      total += report_total( 'collections', status: status )
      total += report_total( 'works', status: status )
      total += report_total( 'file_sets', status: status )
      return total
    end

    def report_total_lines( status: nil )
      report_total_line( 'collections', status: status )
      report_total_line( 'works', status: status )
      report_total_line( 'file_sets', status: status )
      report_total_size_line( 'collections', status: status )
      report_total_size_line( 'works', status: status )
    end

    def size_of( file_set )
      return 0 if file_set.nil?
      file = nil
      begin
        file = file_set.original_file
        if file.nil?
          @msg_handler.msg_error "Original file nil for file set #{file_set.id}" if @msg_handler.present?
        end
      rescue Exception => e # rubocop:disable Lint/RescueException, Lint/UselessAssignment
        @msg_handler.msg_error "Accessing original file exception for file set #{file_set.id}" if @msg_handler.present?
        return 0
      end
      return 0 if file.nil?
      file.size
    end

    def status_label( status )
      if status.blank?
        ''
      else
        "#{status.humanize( capitalize: false )} "
      end
    end

    def tagged( base_tag:, status: nil )
      tag = if status.present?
              "#{base_tag}_#{status}"
            else
              base_tag
            end
      @tagged_totals[tag]
    end

    def to_date( date )
      return date.strftime( "%Y%m%d %H%M%S" ) if date.respond_to? :strftime
      return date.to_s
    end

    def top_ten( hash )
      # brute force with too many sorts...
      top = []
      return top if hash.nil?
      hash.each_pair do |key, value|
        if 10 > top.size
          top << [key, value]
          top.sort_by! { |key_value| 0 - key_value[1] }
        else
          key_value_to_insert = [key, value]
          top.map! do |key_value|
            if key_value_to_insert[1] > key_value[1]
              old_key_value = key_value
              key_value = key_value_to_insert
              key_value_to_insert = old_key_value
            end
            key_value
          end
        end
      end
      top
    end

    def top_ten_print( header, top_ten )
      out_report << header << "\n"
      out_report << "Skipping due to nil hash\n" if top_ten.nil?
      return if top_ten.nil?
      index = 0
      top_ten.each do |a|
        index += 1
        out_report << index << ') ' << a[0].to_s << ' occurred ' << a[1]
        out_report << if 1 == a[1]
                        " time"
                      else
                        " times"
                      end
        out_report << "\n"
      end
    end

    def total( name )
      @totals[name]
    end

    def works( count )
      if 1 == count
        '1 work'
      else
        "#{count} works"
      end
    end

  end

end
