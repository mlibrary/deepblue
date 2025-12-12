# frozen_string_literal: true
class MultiValueSelectInput < MultiValueInput

  mattr_accessor :multi_value_select_input_debug_verbose, default: false

  # Overriding so that the class is correct and the javascript for will work on this.
  # See https://github.com/samvera/hydra-editor/blob/4da9c0ea542f7fde512a306ec3cc90380691138b/app/assets/javascripts/hydra-editor/field_manager.es6#L61
  def input_type
    'multi_value'
  end

  private

  def select_options
    @select_options ||= begin
      collection = options.delete(:collection) || self.class.boolean_collection
      collection.respond_to?(:call) ? collection.call : collection.to_a
    end
  end

  def build_field_options(value) # rubocop:disable Metrics/MethodLength (builder method)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           #"is_draft=#{is_draft}",
                                           "" ] if multi_value_select_input_debug_verbose

    field_options = input_html_options.dup

    field_options[:value] = value
    if @rendered_first_element
      field_options[:id] = nil
      field_options[:required] = nil
    else
      field_options[:id] ||= input_dom_id
    end
    field_options[:class] ||= []
    field_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    field_options[:'aria-labelledby'] = label_id
    # field_options[:add_text] = "Add Text"
    # field_options[:remove_text] = "Remove Text"
    field_options.delete(:multiple)
    field_options.delete(:item_helper)
    field_options.merge!(options.slice(:include_blank))

    @rendered_first_element = true

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "field_options.pretty_inspect=",
                                           field_options.pretty_inspect,
                                           "" ] if multi_value_select_input_debug_verbose

    field_options
  end

  def build_field(value, index)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "value.class.name=#{value.class.name}",
                                           #"is_draft=#{is_draft}",
                                           "" ] if multi_value_select_input_debug_verbose

    render_options = select_options
    html_options = build_field_options(value)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "html_options.pretty_inspect=",
                                           html_options.pretty_inspect,
                                           "" ] if multi_value_select_input_debug_verbose
    (render_options, html_options) = options[:item_helper].call(value, index, render_options, html_options) if options[:item_helper]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "render_options.pretty_inspect=",
                                           render_options.pretty_inspect,
                                           "" ] if multi_value_select_input_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "html_options.pretty_inspect=",
                                           html_options.pretty_inspect,
                                           "" ] if multi_value_select_input_debug_verbose
    template_options_for_select = template.options_for_select(render_options, value)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "template_options_for_select.pretty_inspect=",
                                           template_options_for_select.pretty_inspect,
                                           "" ] if multi_value_select_input_debug_verbose
    template.select_tag(attribute_name, template_options_for_select, html_options)
  end
end
