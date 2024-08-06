# frozen_string_literal: true
#require_relative "../../lib/helpers/blacklight/blacklight_helper_behavior"

module BlacklightDepHelper

  include Blacklight::BlacklightHelperBehavior

  def dep_document_has_value? document, field_config
    document.has?(field_config.field) ||
      (document.has_highlight_field? field_config.field if field_config.highlight) ||
      field_config.accessor
  end

  def dep_index_field_label document, field
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "document=#{document.pretty_inspect}",
    #                                        "field=#{field}",
    #                                        "" ]
    field_config = blacklight_config.index_fields_for(document_presenter(document).display_type)[field]
    field_config ||= Blacklight::Configuration::NullField.new(key: field)

    field_config.display_label('index')
  end

  def dep_render_index_field_label *args
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "args.class.name=#{args.class.name}",
    #                                        "args.respond_to?(:extract_options!)=#{args.respond_to?(:extract_options!)}",
    #                                        "args=#{args.pretty_inspect}",
    #                                        "" ]
    begin
      # simple_format(Array(args[:value]).flatten.join(' '))
      # render_index_field_label *args
      options = args.extract_options!
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "options=#{options}",
      #                                        "" ]
      document = args.first
      field = options[:field]
      label = options[:label] || dep_index_field_label(document, field)
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "field=#{field}",
      #                                        "label=#{label}",
      #                                        "" ]
      rv = html_escape t(:"blacklight.search.index.#{document_index_view_type}.label", default: :'blacklight.search.index.label', label: label)
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "rv.class.name=#{rv.class.name}",
      #                                        "rv=#{rv}",
      #                                        "" ]
      return rv
    rescue Exception => e
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "e=#{e.pretty_inspect}",
                                             "e.backtrace=#{e.backtrace.pretty_inspect}",
                                             "" ] # + caller_locations(0,30)
      return html_escape e.to_s
    end
  end

  def dep_should_render_field?(field_config, *args)
    blacklight_configuration_context.evaluate_if_unless_configuration field_config, *args
  end

  def dep_should_render_index_field? document, field_config
    dep_should_render_field?(field_config, document) && dep_document_has_value?(document, field_config)
  end

end
