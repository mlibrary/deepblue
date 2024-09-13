# frozen_string_literal: true
# Added: Hyrax4
module Hyrax
  class FeaturedWorksController < ApplicationController

    mattr_accessor :featured_works_controller_debug, default: false

    def index
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "" ] if featured_works_controller_debug
      @featured_work = FeaturedWork.find_by(work_id: params[:id])
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@featured_work=#{@featured_work}",
                                             "" ] if featured_works_controller_debug
      if @featured_work.blank?
        msg = create_it
      else
        msg = destroy_it if @featured_work.present?
      end
      curation_concern = DataSet.find params[:id]
      redirect_to [main_app, curation_concern], notice: msg
    end

    def create_it
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if featured_works_controller_debug
      authorize! :create, FeaturedWork
      @featured_work = FeaturedWork.new(work_id: params[:id])

      return "Work is now featured." if @featured_work.save
      return "Error: #{@featured_work.errors}"
    end

    def destroy_it
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if featured_works_controller_debug
      authorize! :destroy, FeaturedWork
      @featured_work = FeaturedWork.find_by(work_id: params[:id])
      @featured_work&.destroy

      return "Work is no longer featured."
    end
  end
end
