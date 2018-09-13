# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'

  class CurationConcernReportTask < AbstractTask

    DEFAULT_FILE_EXT_RE = Regexp.compile( '^.+\.([^\.]+)$' ).freeze

    attr_accessor :file_ext_re

    attr_accessor :authors, :depositors, :extensions
    attr_accessor :collections_file, :works_file, :file_sets_file
    attr_accessor :collection_size, :work_size
    attr_accessor :out_report
    attr_accessor :out_collections, :out_works, :out_file_sets
    attr_accessor :total_collections, :total_works, :total_file_sets
    attr_accessor :total_collections_size, :total_works_size
    attr_accessor :work_ids_reported

    def initialize( options: {} )
      super( options: options )
      # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      # TODO: report_dir
      # TODO: file_prefix
      @file_ext_re = DEFAULT_FILE_EXT_RE
    end

    protected

      def initialize_report_values
        @total_collections = 0
        @total_works = 0
        @total_file_sets = 0
        @total_works_size = 0
        @total_collections_size = 0
        @authors = Hash.new( 0 )
        @depositors = Hash.new( 0 )
        @extensions = Hash.new( 0 )
        @work_ids_reported = {}
        @out_report = StringIO.new
      end

      def collection_file_set_count_and_size( collection_work_ids: )
        file_set_count = 0
        total_size = 0
        collection_work_ids.each do |id|
          w = ActiveFedora::Base.find id
          next unless w.respond_to? :file_sets
          # print 'w'
          w.file_sets do |fs|
            # print 'f'
            file_set_count += 1
            total_size += fs.original_file.size
          end
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

      def parent_ids( work: )
        work.member_of_collection_ids
      end

      def print_collection_line( out, collection: nil, header: false )
        if header
          out << 'Id'
          out << ',' << 'Create date'
          out << ',' << 'Update date'
          out << ',' << 'Depositor'
          out << ',' << 'Visibility'
          out << ',' << 'Work count'
          out << ',' << 'File set count'
          out << ',' << 'Total size'
          out << ',' << 'Total size readable'
          out << ',' << 'Discipline'
          out << ',' << 'Creators'
          out << ',' << 'Work ids'
        else
          return out if collection.nil?
          out << collection.id.to_s
          out << ',' << '"' << to_date( collection.create_date ) << '"'
          out << ',' << '"' << to_date( collection.date_modified ) << '"'
          out << ',' << '"' << collection.depositor << '"'
          out << ',' << '"' << collection.visibility << '"'
          col_work_ids = collection_work_ids( collection: collection )
          out << ',' << col_work_ids.size.to_s
          file_set_count, total_size = collection_file_set_count_and_size( collection_work_ids: col_work_ids )
          out << ',' << file_set_count.to_s
          out << ',' << total_size.to_s
          out << ',' << human_readable( total_size ).to_s
          out << ',' << '"' << collection.subject.join( '; ' ) << '"'
          out << ',' << '"' << collection.creator.join( '; ' ) << '"'
          out << ',' << '"' << col_work_ids.join( ' ' ) << '"'
        end
        out << "\n"
        out
      end

      def print_file_set_line( out, work_id: nil, file_set: nil, file_size: 0, file_ext: '', header: false )
        if header
          out << 'Id'
          out << ',' << 'Parent work id'
          out << ',' << 'Update date'
          out << ',' << 'Depositor'
          out << ',' << 'Visibility'
          out << ',' << 'File size'
          out << ',' << 'File size print'
          out << ',' << 'File ext'
          out << ',' << 'File name'
          out << ',' << 'Thumbnail id'
        else
          return out if file_set.nil?
          out << file_set.id.to_s
          out << ',' << work_id.to_s
          out << ',' << '"' << to_date( file_set.date_modified ) << '"'
          out << ',' << '"' << file_set.depositor << '"'
          out << ',' << '"' << file_set.visibility << '"'
          out << ',' << file_size.to_s
          out << ',' << human_readable( file_size ).to_s
          out << ',' << file_ext
          out << ',' << '"' << file_set.label << '"'
          out << ',' << '"' << (file_set.thumbnail_id.nil? ? '' : file_set.thumbnail_id).to_s << '"'
        end
        out << "\n"
        out
      end

      def print_work_line( out, work: nil, work_size: 0, header: false )
        if header
          out << 'Id'
          out << ',' << 'Create date'
          out << ',' << 'Update date'
          out << ',' << 'Depositor'
          out << ',' << 'Author email'
          out << ',' << 'Visibility'
          out << ',' << 'File set count'
          out << ',' << 'Work size'
          out << ',' << 'Work size print'
          out << ',' << 'Parent ids'
          out << ',' << 'Discipline'
          out << ',' << 'Creators'
          out << ',' << 'Thumbnail id'
          out << ',' << 'DOI'
        else
          return out if work.nil?
          out << work.id.to_s
          out << ',' << '"' << to_date( work.create_date ) << '"'
          out << ',' << '"' << to_date( work.date_modified ) << '"'
          out << ',' << '"' << work.depositor << '"'
          out << ',' << '"' << work.authoremail << '"'
          out << ',' << '"' << work.visibility << '"'
          out << ',' << work.file_set_ids.size.to_s
          out << ',' << work_size.to_s
          out << ',' << human_readable( work_size ).to_s
          parent_ids = parent_ids( work: work )
          out << ',' << '"' << parent_ids.join( ' ' ) << '"'
          out << ',' << '"' << TaskHelper.work_discipline( work: work ).join( '; ' ) << '"'
          out << ',' << '"' << work.creator.join( '; ' ) << '"'
          out << ',' << '"' << (work.thumbnail_id.nil? ? '' : work.thumbnail_id).to_s << '"'
          out << ',' << '"' << (work.doi.nil? ? '' : work.doi).to_s << '"'
        end
        out << "\n"
        out
      end

      def quote( out, str )
        out << '"' << str << '"'
        out
      end

      def report_collection( collection: )
        return if collection.blank?
        return unless collection.is_a? Collection
        @total_collections += 1
        # TODO: collection_authors, collection_depositors
        # authors[collection.authoremail] = authors[collection.authoremail] + 1
        # depositors[collection.depositor] = depositors[collection.depositor] + 1
        @collection_size = 0
        collection_files = 0
        work_ids = collection_work_ids( collection: collection )
        file_set_count, _total_size = collection_file_set_count_and_size( collection_work_ids: work_ids )
        print "[#{collection.id}] has #{works( work_ids.count )} and #{files( file_set_count )}..."
        STDOUT.flush
        work_ids.each do |wid|
          put 'n' if wid.nil?
          next if wid.nil?
          if work_ids_reported.key?( wid )
            print "#{wid} already reported.\n"
            next
          end
          work = TaskHelper.work_find( id: wid )
          @total_works += 1
          authors[work.authoremail] = authors[work.authoremail] + 1
          depositors[work.depositor] = depositors[work.depositor] + 1
          @work_size = 0
          collection_files += work.file_sets.count
          report_file_sets( work: work, in_collection: false )
          work_ids_reported[work.id] = true
          print_work_line( out_works, work: work, work_size: @work_size )
        end
        print " #{human_readable( @collection_size )} in #{files( collection_files )}\n"
        STDOUT.flush
        print_collection_line( out_collections, collection: collection )
      end

      def report_collections
        Collection.all.each do |collection|
          report_collection( collection: collection )
        end
      end

      def report_curation_concerns( ids: )
        return if ids.blank?
        ids.each do |id|
          curation_concern = ActiveFedora::Base.find id
          report_collection( collection: curation_concern )
          report_work( work: curation_concern )
        end
      end

      def report_file_sets( work:, in_collection: false )
        work.file_sets.each do |fs|
          @total_file_sets += 1
          size = size_of fs
          ext = extension_for fs
          extensions[ext] = extensions[ext] + 1 unless '' == ext
          print_file_set_line( out_file_sets, work_id: work.id, file_set: fs, file_size: size, file_ext: ext )
          @work_size += size
          @collection_size += size if in_collection
          @total_collections_size += size
          @total_works_size += size
        end
      end

      def report_work( work: )
        return if work.nil?
        return unless TaskHelper.work? work
        if work_ids_reported.key?( work.id )
          print "#{work.id} already reported.\n"
          return
        end
        @total_works += 1
        authors[work.authoremail] = authors[work.authoremail] + 1
        depositors[work.depositor] = depositors[work.depositor] + 1
        @work_size = 0
        print "#{work.id} has #{files(work.file_set_ids.size)}..."
        STDOUT.flush
        report_file_sets( work: work )
        print " #{human_readable( @work_size )}\n"
        STDOUT.flush
        work_ids_reported[work.id] = true
        print_work_line( out_works, work: work, work_size: @work_size )
      end

      def report_works
        TaskHelper.all_works.each do |work|
          report_work( work: work )
        end
      end

      def size_of( af )
        return 0 if af.nil?
        file = nil
        begin
          file = af.original_file
        rescue Exception => e # rubocop:disable Lint/RescueException, Lint/UselessAssignment
          return 0
        end
        return 0 if file.nil?
        file.size
      end

      def to_date( date )
        return date.strftime( "%Y%m%d %H%M%S" ) if date.respond_to? :strftime
        return date.to_s
      end

      def top_ten( hash )
        # brute force with too many sorts...
        top = []
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

      def top_ten_print( out, header, top_ten )
        out << header << "\n"
        index = 0
        top_ten.each do |a|
          index += 1
          out << index << ') ' << a[0].to_s << ' occured ' << a[1]
          out << if 1 == a[1]
                   " time"
                 else
                   " times"
                 end
          out << "\n"
        end
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
