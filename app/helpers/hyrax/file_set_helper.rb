
module Hyrax::FileSetHelper

  mattr_accessor :file_set_helper_debug_verbose, default: false

  def parent_path(parent)
    if parent.is_a?(Collection)
      main_app.collection_path(parent)
    else
      polymorphic_path([main_app, parent])
    end
  end

  def media_display( file_set, current_ability, presenter = nil, locals = {} )
    ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                          "file_set.class.name=#{file_set.class.name}",
                                          "presenter.class.name=#{presenter.class.name}",
                                          "locals.keys=#{locals.keys}",
                                          ""] if file_set_helper_debug_verbose
    # file_set = ::SolrDocument.find( file_set.id ) if file_set.is_a? FileSet
    partial = media_display_partial( file_set )
    presenter = to_ds_file_set_presenter( file_set, current_ability ) if presenter.blank?
    locals = locals.merge( file_set: file_set, presenter: presenter )
    ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                          "file_set.class.name=#{file_set.class.name}",
                                          "presenter.class.name=#{presenter.class.name}",
                                          "locals.keys=#{locals.keys}",
                                          "partial=#{partial}",
                                          ""] if file_set_helper_debug_verbose
    render partial, locals
  end

  def to_ds_file_set_presenter( file_set, current_ability )
    return ::Hyrax::DsFileSetPresenter.new( file_set, current_ability ) if file_set.is_a? ::SolrDocument
    ::Hyrax::DsFileSetPresenter( ::SolrDocument.find( file_set.id ), current_ability )
  end

  def media_display_partial( file_set )
    'hyrax/file_sets/media_display/' +
      if file_set.image?
        'image'
      elsif file_set.video?
        'video'
      elsif file_set.audio?
        'audio'
      elsif file_set.pdf?
        'pdf'
      elsif file_set.office_document?
        'office_document'
      else
        'default'
      end
  end
  # rubocop:enable Metrics/MethodLength

end
