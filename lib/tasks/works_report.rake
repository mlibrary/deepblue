# frozen_string_literal: true

namespace :deepblue do

  desc 'Write report of all works'
  task works_report: :environment do
    Deepblue::WorksReport.run
  end

end

module Deepblue

  require 'stringio'

  class WorksReport

    # Produce a report containing:
    # * # of datasets
    # * Total size of the datasets in GB
    # * # of unique depositors
    # * # of repeat depositors
    # * Top 10 file formats (csv, nc, txt, pdf, etc)
    # * Discipline of dataset
    # * Names of depositors

    def self.files( count )
      if 1 == count
        '1 file'
      else
        "#{count} files"
      end
    end

    def self.human_readable( value )
      ActiveSupport::NumberHelper.number_to_human_size( value )
    end

    def self.print_work_line( out, work: nil, work_size: 0, header: false )
      if header
        out << 'Id'
        out << ',' << 'Create date'
        out << ',' << 'Depositor'
        out << ',' << 'Author email'
        out << ',' << 'Visibility'
        out << ',' << 'File set count'
        out << ',' << 'Work size'
        out << ',' << 'Work size print'
        out << ',' << 'Discipline'
        out << ',' << 'Creators'
        out << ',' << 'Thumbnail id'
        out << ',' << 'DOI'
      else
        return out if work.nil?
        out << work.id.to_s
        out << ',' << '"' << work.create_date.strftime( "%Y%m%d %H%M%S" ) << '"'
        out << ',' << '"' << work.depositor << '"'
        out << ',' << '"' << work.authoremail << '"'
        out << ',' << '"' << work.visibility << '"'
        out << ',' << work.file_set_ids.size.to_s
        out << ',' << work_size.to_s
        out << ',' << human_readable( work_size ).to_s
        out << ',' << '"' << work.subject.join( '; ' ) << '"'
        out << ',' << '"' << work.creator.join( '; ' ) << '"'
        out << ',' << '"' << (work.thumbnail_id.nil? ? '' : work.thumbnail_id).to_s << '"'
        out << ',' << '"' << (work.doi.nil? ? '' : work.doi).to_s << '"'
      end
      out << "\n"
      out
    end

    def self.print_file_set_line( out, work_id: nil, file_set: nil, file_size: 0, file_ext: '', header: false )
      if header
        out << 'Id'
        out << ',' << 'Work id'
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

    def self.quote( out, str )
      out << '"' << str << '"'
      out
    end

    def self.size_of( af )
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

    def self.extension_for( af )
      return '' if af.nil?
      match = @@file_ext_re.match( af.label )
      return '' unless match
      ext = match[1]
      ext = ext.downcase
      return ext
    end

    def self.top_ten( hash )
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

    def self.top_ten_print( out, header, top_ten )
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

    def self.run
      works_report = StringIO.new
      works_report << "Report started: " << Time.new.to_s << "\n"
      @@file_ext_re = Regexp.compile( '^.+\.([^\.]+)$' ) # rubocop:disable Style/ClassVars
      prefix = "#{Time.now.strftime('%Y%m%d')}_works_report"
      works_file = Pathname.new( '.' ).join "#{prefix}_works.csv"
      file_sets_file = Pathname.new( '.' ).join "#{prefix}_file_sets.csv"
      out_works = nil
      out_file_sets = nil
      out_works = open( works_file, 'w' )
      out_file_sets = open( file_sets_file, 'w' )
      print_work_line( out_works, header: true )
      print_file_set_line( out_file_sets, header: true )
      all_works = GenericWork.all
      total_works = 0
      total_file_sets = 0
      total_works_size = 0
      authors = Hash.new( 0 )
      depositors = Hash.new( 0 )
      extensions = Hash.new( 0 )
      all_works.each do |work|
        next if work.nil?
        total_works += 1
        authors[work.authoremail] = authors[work.authoremail] + 1
        depositors[work.depositor] = depositors[work.depositor] + 1
        work_size = 0
        print "#{work.id} has #{files(work.file_set_ids.size)}..."
        STDOUT.flush
        work.file_set_ids.each do |fid|
          total_file_sets += 1
          fs = ActiveFedora::Base.find fid
          size = size_of fs
          ext = extension_for fs
          extensions[ext] = extensions[ext] + 1 unless '' == ext
          print_file_set_line( out_file_sets, work_id: work.id, file_set: fs, file_size: size, file_ext: ext )
          work_size += size
          total_works_size += size
        end
        print " #{human_readable( work_size )}\n"
        STDOUT.flush
        print_work_line( out_works, work: work, work_size: work_size )
      end

      print "#{works_file}\n"
      print "#{file_sets_file}\n"

      works_report << "Report finished: " << Time.new.to_s << "\n"
      works_report << "Total works: #{total_works}" << "\n"
      works_report << "Total file_sets: #{total_file_sets}" << "\n"
      works_report << "Total works size: #{human_readable(total_works_size)}\n"
      works_report << "Unique authors: #{authors.size}\n"
      count = 0
      authors.each_pair { |_key, value| count += 1 if value > 1 }
      works_report << "Repeat authors: #{count}\n"
      works_report << "Unique depositors: #{depositors.size}\n"
      count = 0
      depositors.each_pair { |_key, value| count += 1 if value > 1 }
      works_report << "Repeat depositors: #{count}\n"
      top = top_ten( authors )
      top_ten_print( works_report, "\nTop ten authors:", top )
      top = top_ten( depositors )
      top_ten_print( works_report, "\nTop ten depositors:", top )
      top = top_ten( extensions )
      top_ten_print( works_report, "\nTop ten extensions:", top )
      works_report_file = Pathname.new( '.' ).join "#{prefix}.txt"
      open( works_report_file, 'w' ) { |out| out << works_report.string }
      print "\n"
      print "\n"
      print works_report.string
      print "\n"
      STDOUT.flush
    ensure
      unless out_works.nil?
        out_works.flush
        out_works.close
      end
      unless out_file_sets.nil?
        out_file_sets.flush
        out_file_sets.close
      end
    end

  end

end
