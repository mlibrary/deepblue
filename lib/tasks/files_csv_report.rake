# frozen_string_literal: true

namespace :deepblue do

  desc 'Generate files report to csv file'
  task files_csv_report: :environment do
    Deepblue::FilesCsvReport.new.run
  end

end

module Deepblue

  require 'tasks/abstract_task'

  class FilesCsvReport < AbstractTask

    def run
      @count = 0
      @count_nl = 100
      tmp_dir = ENV['TMPDIR'] || "/tmp"
      target_file = "#{tmp_dir}/files_report.csv"
      puts "target_file=#{target_file}"
      open( target_file, 'w' ) do |out|
        out.puts "w_id,fs_id,visibility,depositor,date_uploaded,time_uploaded,label,dupe,file0_nil?,original_checksum,original_size,uri_bytes"
        TaskHelper.all_works.each { |w| report_work( out, w ) }
      end
      puts
    end

    def pacify( x )
      x = x.to_s
      @count += x.length
      if @count > @count_nl
        puts x
        @count = 0
      else
        print x
        STDOUT.flush
      end
    end

    def pacify_bracket( x, bracket_open: '(', bracket_close: ')' )
      x = x.to_s
      x = "#{bracket_open}#{x}#{bracket_close}" if x.length > 1
      pacify x
    end

    def get_uri_byte_count( fs )
      bytes_expected = -1
      source_uri = fs.files[0].uri.value
      bytes_expected = ExportFilesHelper.export_file_uri_bytes( source_uri: source_uri )
      return bytes_expected
    rescue Exception => e # rubocop:disable Lint/RescueException, Lint/UselessAssignment
      pacify '!'
      return bytes_expected
    end

    def report_work( out, w )
      pacify 'w'
      labels = Hash.new( 0 )
      w.file_sets.each do |fs|
        t = fs.label
        labels[t] = labels[t] + 1
        labels[t] < 2 ? pacify( '.' ) : pacify_bracket( labels[t] )
      end
      pacify 'f'
      w.file_sets.each do |fs|
        begin
          pacify '.'
          file0_nil = ( fs.files[0].nil? ? 'yes' : 'no' )
          dupe = ( labels[fs.label] < 2 ? 'no' : 'yes' )
          date_uploaded = fs.date_uploaded
          time_uploaded = ''
          if fs.date_uploaded.respond_to? :strftime
            date_uploaded = fs.date_uploaded.strftime('%Y%m%d')
            time_uploaded = fs.date_uploaded.strftime('%H%M%S')
          end
          original_checksum = ''
          begin
            original_checksum = fs.original_checksum[0] unless fs.original_checksum.length.zero?
          rescue Exception => e # rubocop:disable Lint/RescueException
            pacify '!'
            original_checksum = "\"#{e.class}: #{e.message}>\""
          end
          original_size = ''
          begin
            original_size = fs.original_file.size
          rescue Exception => e # rubocop:disable Lint/RescueException
            pacify '!'
            original_size = "\"#{e.class}: #{e.message}>\""
          end
          uri_bytes = get_uri_byte_count fs
          out.puts "#{w.id},#{fs.id},#{fs.visibility},#{fs.depositor},\"#{date_uploaded}\",\"#{time_uploaded}\",\"#{fs.label}\",#{dupe},#{file0_nil},#{original_checksum},#{original_size},#{uri_bytes}"
        rescue Exception => e # rubocop:disable Lint/RescueException
          pacify "<#{fs.id} -- #{e.class}: #{e.message}>"
        end
      end
    end

  end

end
