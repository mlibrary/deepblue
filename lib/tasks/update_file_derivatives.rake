# frozen_string_literal: true

namespace :deepblue do

  desc 'Find all file sets with files that need derivative updates'
  task update_all_work_file_sets: :environment do
    Deepblue::UpdateAllWorkFileSets.run
  end

  desc 'Find file sets with files that need derivative updates for the given works'
  task update_work_file_sets: :environment do
    Deepblue::UpdateWorkFileSets.run
  end

end

# rubocop:disable Layout/SpaceBeforeSemicolon, Style/Semicolon
module Deepblue

  require 'hydra/file_characterization'
  require 'logger'

  class UpdateAllWorkFileSets
    def self.run
      works = TaskHelper.all_works
      UpdateFileDerivatives.new( works ).run
    end
  end

  class UpdateWorkFileSets
    def self.run
      # TODO: pass in the work ids
      works = []
      # works << TaskHelper.work_find( id: '1n79h444s' )
      # works << TaskHelper.work_find( id: 'ft848q70w' )
      # works << TaskHelper.work_find( id: 'pr76f340k' )
      works << TaskHelper.work_find( id: 'kd17cs870' )
      UpdateFileDerivatives.new( works ).run
    end
  end

  class UpdateFileDerivatives

    def initialize( works, restart_with_work_id: nil )
      puts "ENV['TMPDIR']=#{ENV['TMPDIR']}"
      # puts "DeepBlueDocs::Application.config.tmpdir=#{DeepBlueDocs::Application.config.tmpdir}"
      puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}"
      @tmpdir = Pathname.new "/deepbluedata-prep/fedora-extract"
      Dir.mkdir @tmpdir unless Dir.exist? @tmpdir
      @java_io_tmpdir = @tmpdir
      Dir.mkdir @java_io_tmpdir unless Dir.exist? @java_io_tmpdir
      ENV['_JAVA_OPTIONS'] = '-Djava.io.tmpdir=' + ENV['TMPDIR']
      puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}"
      puts `echo $_JAVA_OPTIONS`.to_s
      @do_report_tmpdir_usage = true

      @works = works
      @characterize = true
      @create_derivatives = true
      @copy_the_file_to_tmpdir = true
      @update_work_total_file_size = false
      @verbose = false
      @verbose_ext = false
      @verbose_file_size = false
      @report_error_full_backtrace = false

      @derivative_min_file_size = 0 # can skip over small sizes
      @derivative_max_file_size = 100_000_000 # something smaller than 4_000_000_000
      # @derivative_max_file_size = DeepBlueDocs::Application.config.derivative_max_file_size
      @skip_derivative_ext = { '.zip' => true, '.gz' => true }
      @tracking_report_to_console = false

      @restart_with_work_id = restart_with_work_id

      @skip_total_size_for_work = {}
      @tracking = Hash.new { |h, key| h[key] = [] }
    end

    def add_to_fids_to_characterize( fid )
      return if @fids_to_characterize_set[fid]
      @fids_to_characterize_list << fid
      @fids_to_characterize_set[fid] = true
    end

    def characterize_file_set( fid )
      pacify '.'
      af = ActiveFedora::Base.find fid
      if nil_original_file? af
        pacify '<of.nil>'
        return
      end
      pacify "{#{human_readable(original_size( af ))}}" if @verbose_file_size
      if original_file_too_large? af
        pacify 'L'
        return
      end
      if original_file_too_small? af
        pacify 's'
        return
      end
      # return unless @copy_the_file_to_tmpdir
      begin
        characterize_fs( af )
        create_derivatives_fs( af )
      rescue OpenURI::HTTPError => _e
        # TODO: record the problem
        pacify '<!HTTPError!>'
      rescue Exception => e # rubocop:disable Lint/RescueException
        puts "characterize_file_set(#{fid}) #{e.class}: #{e.message}"
      ensure
        delete_file_from_tmpdir af
      end
    end

    def characterize_fs( file_set )
      # see characterization_helper.rb - CharacterizationHelper.characterize
      return unless no_original_checksum? file_set
      file_ext = File.extname file_set.label
      if DeepBlueDocs::Application.config.characterize_excluded_ext_set.key? file_ext
        pacify "<!#{file_ext}>"
        return
      end
      unless file_set.characterization_proxy?
        pacify '<!cp>'
        return
      end
      pacify 'c'
      return unless @characterize
      return unless @copy_the_file_to_tmpdir
      begin
        file = copy_file_to_tmpdir file_set
        open_file = File.new file.expand_path
        Hydra::Works::CharacterizationService.run( file_set.characterization_proxy, open_file )
        file_set.characterization_proxy.save!
        file_set.update_index
        # file_set.parent.in_collections.each(&:update_index) if file_set.parent
      rescue OpenURI::HTTPError => _e
        # TODO: record the problem
        pacify '<!HTTPError!>'
      rescue Exception => e # rubocop:disable Lint/RescueException
        puts "characterize_fs(#{file_set.id}) #{e.class}: #{e.message}"
      end
    end

    def target_file_for( fs )
      @tmpdir.join fs.label
    end

    def copy_file_to_tmpdir( fs )
      target_file = target_file_for fs
      unless File.exist? target_file
        pacify 'C'
        source_uri = fs.files[0].uri.value
        ExportFilesHelper.export_file_uri( source_uri: source_uri, target_file: target_file )
      end
      target_file
    end

    def create_derivatives_fs( file_set )
      # see characterization_helper.rb - CharacterizationHelper.create_derivatives
      file_ext = File.extname file_set.label
      if DeepBlueDocs::Application.config.derivative_excluded_ext_set.key? file_ext
        pacify "<!#{file_ext}>"
        return
      end
      return unless no_thumbnail? file_set
      if skip_derivative_ext? file_set
        pacify 'x'
        return
      end
      unless create_derivatives_desired_mime_type?( file_set )
        pacify 'x'
        return
      end
      if file_set.video? && !Hyrax.config.enable_ffmpeg
        pacify 'v'
        return
      end
      pacify 'd'
      return unless @create_derivatives
      return unless @copy_the_file_to_tmpdir
      file = copy_file_to_tmpdir file_set
      file_set.create_derivatives( file.expand_path )
      file_set.reload
      file_set.update_index
      file_set.parent.update_index if parent_needs_reindex?(file_set)
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "create_derivatives_fs(#{file_set}) #{e.class}: #{e.message}"
    end

    def create_derivatives_desired_mime_type?( file_set )
      # see FileSetDerivativesService
      mime_type = file_set.mime_type
      case mime_type
      when *file_set.class.pdf_mime_types             then return true
      when *file_set.class.office_document_mime_types then return true
      when *file_set.class.audio_mime_types           then return true
      when *file_set.class.video_mime_types           then return true
      when *file_set.class.image_mime_types           then return true
      end
      return false
    end

    def do_characterize( work )
      # return unless @characterize
      if @fids_to_characterize_list.size && @do_characterize_work.zero?
        @fids_to_characterize_list = work.file_set_ids
      end
      return if @fids_to_characterize_list.size.zero?
      print "Characterize #{work.id} "; STDOUT.flush
      count = 0
      @fids_to_characterize_list.each do |fid|
        count += 1
        if ( count % 20 ).zero?
          pacify "(#{count})"
          pacify report_tmpdir_usage( inline: true, prefix: '(', postfix: ')' ).to_s
        end
        characterize_file_set fid
      end
      if @characterize && !@skip_total_size_for_work[work.id] && @update_work_total_file_size
        pacify '<U>'
        work.update_total_file_size!
      end
      print "\n"; STDOUT.flush
    end

    # If this file_set is the thumbnail for the parent work,
    # then the parent also needs to be reindexed.
    def parent_needs_reindex?(file_set)
      return false unless file_set.parent
      file_set.parent.thumbnail_id == file_set.id
    end

    def delete_file_from_tmpdir( fs )
      target_file = target_file_for fs
      File.delete target_file if File.exist? target_file
    end

    def human_readable( value )
      if value.blank?
        'n/a'
      else
        ActiveSupport::NumberHelper.number_to_human_size( value )
      end
    end

    def skip_derivative_ext?(fs )
      ext = File.extname fs.label
      pacify "{#{ext}}" if @verbose_ext
      @skip_derivative_ext.key? ext
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap { |logger| logger.level = Logger::INFO }
    end

    def nil_original_file?( fs )
      begin
        file = fs.original_file
      rescue Exception => _ignore # rubocop:disable Lint/RescueException
        file = nil
      end
      file.nil?
    end

    def nil_date_modified?( af )
      af.date_modified.nil?
    end

    def no_original_checksum?( af )
      af.original_checksum.size.zero?
    end

    def no_thumbnail?( af )
      if af.thumbnail_id.nil?
        true
      else
        !thumbnail?( thumbnail_fetch( af ) )
      end
    end

    def original_file_too_large?( fs )
      if original_size( fs ) > @derivative_max_file_size
        true
      else
        false
      end
    end

    def original_file_too_small?( fs )
      if original_size( fs ) < @derivative_min_file_size
        true
      else
        false
      end
    end

    def original_size( fs )
      fs.original_file.size
    rescue Exception => e # rubocop:disable Lint/RescueException
      report_error( "fs.original_file.size", e )
    end

    def pacify( x )
      print x; STDOUT.flush
    end

    def report_error( msg, e )
      if @report_error_full_backtrace
        puts "#{msg} #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}\n"
      else
        puts "#{msg} #{e.class}: #{e.message}\n#{e.backtrace[0]}\n"
      end
    end

    def report_tmpdir_usage( inline: false, prefix: '', postfix: "\n" )
      return unless @do_report_tmpdir_usage
      # rubocop:disable Style/IdenticalConditionalBranches
      if inline
        rv = `df -h /tmp`.chop
        rv += ";"
        rv += `du -h --summarize #{@java_io_tmpdir}`.chop
        rv = rv.gsub( /\s+/, ' ' )
        print "#{prefix}#{rv}#{postfix}" ; STDOUT.flush
      else
        print `df -h /tmp` ; STDOUT.flush
        print `du -h --summarize #{@java_io_tmpdir}` ; STDOUT.flush
      end
      # rubocop:enable Style/IdenticalConditionalBranches
    end

    def run
      puts "Started at #{Time.now}"
      total = 0
      file_count = 0
      work_count = 0
      begin
        report_tmpdir_usage( inline: true )
        restarted = @restart_with_work_id.nil?
        @works.map do |w|
          work_count += 1
          puts "(#{work_count}/#{@works.size})" if ( work_count % 10 ).zero?
          if !restarted && !w.nil?
            restarted = true if @restart_with_work_id == w.id
          end
          if w.nil?
            puts "Skipping nil work"
          elsif !restarted
            puts "Seeking restart work id, skipping #{w.id}"
          else
            wid = w.id
            @do_characterize_work = false
            @fids_to_characterize_list = []
            @fids_to_characterize_set = Hash.new( false )
            # print "#{w.id} total_file_size=#{w.total_file_size.class} -- "; STDOUT.flush
            print "#{w.id} total_file_size=#{human_readable(w.total_file_size)} -- " if @verbose
            @tracking[:nil_total_file_size] = (@tracking[:nil_total_file_size] << wid) if w.total_file_size.nil?
            @tracking[:zero_total_file_size] = (@tracking[:zero_total_file_size] << wid) if w.total_file_size.zero?
            @do_characterize_work = w.total_file_size.nil? || w.total_file_size.zero?
            subtotal = 0
            print "#{w.id} has #{w.file_set_ids.size} files ..."; STDOUT.flush
            w.file_set_ids.map do |fid|
              af = ActiveFedora::Base.find fid
              file_count += 1
              if af.nil?
                track( :nil_af, wid, fid )
              else
                ofile = nil
                begin
                  ofile = af.original_file
                rescue Exception => e # rubocop:disable Lint/RescueException
                  report_error( "ofile = af.original_file", e )
                end
                if ofile.nil?
                  @skip_total_size_for_work[wid] = true
                  track( :nil_original_files, wid, fid )
                else
                  thumb_status = thumbnail_status( wid, af )
                  puts thumb_status if @verbose # rubocop:disable Metrics/BlockNesting
                  test_mime_type( wid, af )
                  test_date_modified( wid, af )
                  test_original_checksum( wid, af )
                  test_original_file_size_too_small( wid, af )
                  test_original_file_size_too_large( wid, af )
                  size = ofile.size
                  subtotal += size
                  total += size
                end
                file = nil
                test_files( wid, af )
                begin
                  file = af.files[0]
                rescue Exception => e # rubocop:disable Lint/RescueException
                  report_error( "file = af.files[0]", e )
                end
                if file.nil?
                  track( :nil_fs_files, wid, fid )
                  # else
                  # TODO
                end
              end
            end
            print "Subtotal:" if @verbose
            print " #{human_readable( subtotal )}" ; STDOUT.flush
            report_tmpdir_usage( inline: true, prefix: ' :: ' )
            print "\n" ; STDOUT.flush
            do_characterize w
          end
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        report_error( "UpdateFileDerivatives.run", e )
      end
      begin
        report_tmpdir_usage( inline: true )
        prefix = "#{Time.now.strftime('%Y%m%d')}_update_derivatives_report"
        report_file = Pathname.new( '.' ).join "#{prefix}.txt"
        @out = nil
        @out = open( report_file, 'w' )
        msg = "Finished at #{Time.now}"
        puts msg
        @out << msg << "\n"
        tracking_report( :nil_total_file_size )
        tracking_report( :zero_total_file_size )
        tracking_report( :nil_af )
        tracking_report( :zero_fs_files )
        tracking_report( :nil_fs_files )
        tracking_report( :nil_original_files )
        tracking_report( :nil_mime_type )
        tracking_report( :nil_thumbnail_id )
        tracking_report( :no_thumbnail )
        tracking_report( :nil_date_modified )
        tracking_report( :no_original_checksum )
        tracking_report( :original_file_size_too_small )
        tracking_report( :original_file_size_too_large )
        puts ''
        @out << "\n"
        msg = "Total: #{human_readable( total )} in #{file_count} files and #{@works.size} works."
        puts msg
        @out << msg << "\n"
      ensure
        unless @out.nil?
          @out.flush
          @out.close
        end
      end
    end

    def test_date_modified( wid, af )
      puts value_or_nil('af.date_modified', af.date_modified).to_s if @verbose
      return unless af.date_modified.nil?
      track( :nil_date_modified, wid, af.id ) if nil_date_modified? af
      add_to_fids_to_characterize( af.id )
    end

    def test_files( wid, af )
      return unless 1 > af.files.size
      track( :zero_fs_files, wid, af.id )
    end

    def test_mime_type( wid, af )
      puts value_or_nil('af.mime_type', af.mime_type).to_s if @verbose
      return unless af.mime_type.nil?
      track( :nil_mime_type, wid, af.id )
      add_to_fids_to_characterize( af.id )
    end

    def test_original_checksum( wid, af )
      return unless no_original_checksum? af
      track( :no_original_checksum, wid, af.id )
      add_to_fids_to_characterize( af.id )
    end

    def test_original_file_size_too_large( wid, af )
      return unless original_file_too_large? af
      track( :original_file_size_too_large, wid, af.id )
    end

    def test_original_file_size_too_small( wid, af )
      return unless original_file_too_small? af
      track( :original_file_size_too_small, wid, af.id )
    end

    def track( label, wid, fid )
      @tracking[label] = @tracking[label] << [wid, fid]
    end

    def tracking_report( label )
      msg = "#{label}: #{@tracking[label].size} #{@tracking[label]}"
      @out << msg << "\n"
      return unless @tracking_report_to_console
      puts
      puts msg
    end

    # @return true if there a file on disk for this object, otherwise false
    # @param [FileSet] thumb - the object that is the thumbnail
    def thumbnail?(thumb)
      File.exist?(thumbnail_filepath(thumb))
    end

    def thumbnail_fetch( object )
      return object if object.thumbnail_id == object.id
      ::ActiveFedora::Base.find(object.thumbnail_id)
    rescue ActiveFedora::ObjectNotFoundError
      puts "Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}"
      nil
    end

    # @param [FileSet] thumb - the object that is the thumbnail
    def thumbnail_filepath(thumb)
      Hyrax::DerivativePath.derivative_path_for_reference(thumb, 'thumbnail')
    end

    def thumbnail_status( wid, af )
      fid = af.id
      if af.thumbnail_id.nil?
        track( :nil_thumbnail_id, wid, fid )
        add_to_fids_to_characterize( fid )
        "found file_set with nil thumbnail id for work #{af.id}"
      else
        thumb = thumbnail_fetch af
        if thumbnail? thumb
          "found thumbnail for work #{af.id}"
        else
          track( :no_thumbnail, wid, fid )
          add_to_fids_to_characterize( fid )
          "did not find thumbnail for work #{af.id}"
        end
      end
    end

    def value_or_nil( label, value )
      if value.nil?
        "#{label} is nil"
      else
        "#{label}: #{value}"
      end
    end

  end
  # rubocop:enable Layout/SpaceBeforeSemicolon

end
