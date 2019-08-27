# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../helpers/hyrax/embargo_helper'

  class AboutToExpireEmbargoesService
    include ::Hyrax::EmbargoHelper

    def initialize( email_owner: true, expiration_lead_days: nil, skip_file_sets: true, test_mode: true, to_console: false, verbose: false )
      LoggingHelper.bold_debug [ LoggingHelper.here,
                                  LoggingHelper.called_from,
                                  LoggingHelper.obj_class( 'class', self ),
                                 "email_owner=#{email_owner}",
                                 "expiration_lead_days=#{expiration_lead_days}",
                                 "skip_file_sets=#{skip_file_sets}",
                                 "test_mode=#{test_mode}",
                                 "to_console=#{to_console}",
                                 "verbose=#{verbose}",
                                 "" ]
      @email_owner = email_owner
      @expiration_lead_days = expiration_lead_days
      @skip_file_sets = skip_file_sets
      @test_mode = test_mode
      @to_console = to_console
      @verbose = verbose
    end

    def run
      LoggingHelper.bold_debug [ LoggingHelper.here,
                                 LoggingHelper.called_from,
                                 LoggingHelper.obj_class( 'class', self ),
                                 "@email_owner=#{@email_owner}",
                                 "@expiration_lead_days=#{@expiration_lead_days}",
                                 "@skip_file_sets=#{@skip_file_sets}",
                                 "@test_mode=#{@test_mode}",
                                 "@to_console=#{@to_console}",
                                 "@verbose=#{@verbose}",
                                 "" ]
      @now = DateTime.now
      @assets = Array( assets_under_embargo )
      if @expiration_lead_days.blank?
        about_to_expire_embargoes_for_lead_days( lead_days: 7 )
        about_to_expire_embargoes_for_lead_days( lead_days: 1 )
      else
        @expiration_lead_days = @expiration_lead_days.to_i
        if 0 < @expiration_lead_days
          about_to_expire_embargoes_for_lead_days( lead_days: @expiration_lead_days )
        else
          about_to_expire_embargoes_for_lead_days( lead_days: 7 )
          about_to_expire_embargoes_for_lead_days( lead_days: 1 )
        end
      end
    end

    def about_to_expire_embargoes_for_lead_days( lead_days: )
      run_msg "about_to_expire_embargoes_for_lead_days: lead_days=#{lead_days}"
      # puts "expiration lead days: #{lead_days}" if @test_mode
      lead_date = @now.beginning_of_day + lead_days.days
      lead_date = lead_date.strftime "%Y%m%d"
      run_msg "lead_date=#{lead_date}"
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        embargo_release_date = asset_embargo_release_date( asset: asset )
        embargo_release_date = embargo_release_date.beginning_of_day.strftime "%Y%m%d"
        run_msg "#{asset.id} embargo_release_date=#{embargo_release_date}"
        if embargo_release_date == lead_date
          run_msg "about to call about_to_expire_embargo_email for asset #{asset.id}" if @test_mode
          about_to_expire_embargo_email( asset: asset,
                                         expiration_days: lead_days,
                                         email_owner: @email_owner,
                                         test_mode: @test_mode,
                                         verbose: @verbose ) unless @test_mode
        end
      end
    end

    def run_msg( msg )
      LoggingHelper.debug msg
      puts msg if @to_console
    end

  end

end