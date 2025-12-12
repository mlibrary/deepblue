# frozen_string_literal: true

class ControlledVocabularyInput < MultiValueInput

  mattr_accessor :controlled_vocabulary_input_debug_verbose, default: true

  # # Overriding so that the class is correct and the javascript for will activate for this element.
  # # See https://github.com/samvera/hydra-editor/blob/4da9c0ea542f7fde512a306ec3cc90380691138b/app/assets/javascripts/hydra-editor/field_manager.es6#L61
  # def input_type
  #   'multi_value'.freeze
  # end

  private

  def build_field(value, index)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if controlled_vocabulary_input_debug_verbose

    options = input_html_options.dup
    value = value.resource if value.is_a? ActiveFedora::Base

    build_options(value, index, options) if value.respond_to?(:rdf_label)
    options[:required] = nil if @rendered_first_element
    options[:class] ||= []
    options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    options[:'aria-labelledby'] = label_id
    @rendered_first_element = true
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options.pretty_inspect=",
                                           options.pretty_inspect,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    text_field(options) + hidden_id_field(value, index) + destroy_widget(attribute_name, index)
  end

  def text_field(options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    if options.delete(:type) == 'textarea'
      @builder.text_area(attribute_name, options)
    else
      @builder.text_field(attribute_name, options)
    end
  end

  def id_for_hidden_label(index)
    id_for(attribute_name, index, 'hidden_label')
  end

  def destroy_widget(attribute_name, index)
    @builder.hidden_field(attribute_name,
                          name: name_for(attribute_name, index, '_destroy'),
                          id: id_for(attribute_name, index, '_destroy'),
                          value: '', data: { destroy: true })
  end

  def hidden_id_field(value, index)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    name = name_for(attribute_name, index, 'id')
    id = id_for(attribute_name, index, 'id')
    hidden_value = value.try(:node?) ? '' : value.rdf_subject
    @builder.hidden_field(attribute_name, name: name, id: id, value: hidden_value, data: { id: 'remote' })
  end

  def build_options(value, index, options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options.pretty_inspect=",
                                           options.pretty_inspect,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    options[:name] = name_for(attribute_name, index, 'hidden_label')
    options[:data] ||= {}
    options[:data][:attribute] = attribute_name
    options[:id] = id_for_hidden_label(index)
    if value.node?
      build_options_for_new_row(attribute_name, index, options)
    else
      build_options_for_existing_row(attribute_name, index, value, options)
    end
  end

  def build_options_for_new_row(_attribute_name, _index, options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    options[:value] = ''
    options[:data][:label] = ''
  end

  def build_options_for_existing_row(_attribute_name, _index, value, options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if controlled_vocabulary_input_debug_verbose
    options[:value] = value.rdf_label.first || "Unable to fetch label for #{value.rdf_subject}"
    options[:data][:label] = value.full_label || value.rdf_label
    options[:readonly] = true
  end

  def name_for(attribute_name, index, field)
    "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}]"
  end

  def id_for(attribute_name, index, field)
    [@builder.object_name, "#{attribute_name}_attributes", index, field].join('_')
  end

  def collection
    @collection ||=
      Array(object[attribute_name]).reject { |v| v.to_s.strip.blank? }
  end
end
