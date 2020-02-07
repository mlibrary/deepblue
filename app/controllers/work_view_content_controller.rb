# frozen_string_literal: true

class WorkViewContentController < ApplicationController

  class_attribute :presenter_class
  self.presenter_class = WorkViewContentPresenter

  attr_accessor :file_name, :work_title

  def show
    @work_title = params[:id]
    @file_name = params[:file_id]
    format = params[:format]
    @file_name = "#{@file_name}.#{format}" unless format.empty?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "work_title=#{work_title}",
                                           "file_name=#{file_name}",
                                           "format=#{format}",
                                           "" ]
    @presenter = presenter_class.new( controller: self )
    render 'hyrax/static/work_view_content'
  end

  # def id_check
  #   return if id.blank?
  #   ActiveFedora::Base.find( id )
  # rescue Ldp::Gone => g
  #   @id_msg = "deleted"
  #   @id_deleted = true
  # rescue ActiveFedora::ObjectNotFoundError => e2
  #   @id_msg = "invalid"
  #   @id_invalid = true
  # end
  #
  # def id_valid?
  #   return false if id.blank?
  #   return false if ( id_deleted || id_invalid )
  #   true
  # end

end
