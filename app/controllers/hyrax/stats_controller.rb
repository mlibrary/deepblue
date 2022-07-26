# frozen_string_literal: true
module Hyrax

  require 'csv'

  class StatsController < ApplicationController
    include Hyrax::SingularSubresourceController
    include Hyrax::Breadcrumbs

    before_action :build_breadcrumbs, only: [:work, :file]

    # TODO: New reporting features FlipFlop pattern:
    # Flipflop.enabled?(:analytics_redesign)

    def work
      @stats = Hyrax::WorkUsage.new(params[:id])
    end

    # To download csv files.
    def csv_download
      @stats = Hyrax::WorkUsage.new(params[:id])
      filename = params[:id] + "_stats.csv"
      #This is an example that worked
      #send_data @stats.to_csv, :type => 'text/csv; charset=utf-8; header=present', :disposition => 'attachment; filename=payments.csv'
      target = "attachment`; filename=#{filename}"
      send_data @stats.to_csv, :type => 'text/csv; charset=utf-8; header=present', :disposition => target
    end

    def file
      @stats = Hyrax::FileUsage.new(params[:id])
    end

    private

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'file'
        add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
      when 'work'
        add_breadcrumb @work.to_s, main_app.polymorphic_path(@work)
      end
    end
  end
end
