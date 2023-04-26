module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior
  include Hyrax::Doi::HelperBehavior
  # hyrax-orcid begin
  include Hyrax::Orcid::HelperBehavior # Helpers provided by hyrax-orcid plugin.
  # hyrax-orcid end


  # @param [Hash] options from blacklight invocation of helper_method
  # @see #index_field_link params
  # @return [String]
  def human_readable_file_size(options)
    value = options[:value].first
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
  end

  # def link_to_profile(login)
  #   user = ::User.find_by_user_key(login)
  #   return login if user.nil?
  #
  #   text = if user.respond_to? :name
  #            user.name
  #          else
  #            login
  #          end
  #
  #   href = profile_path(user)
  #
  #   # TODO: ?? still needed ?? Fix the link to the user profiles when the sufia object isn't available.
  #   link_to text, href
  # end

  def self.nbsp_or_value( value )
    return "&nbsp;" if value.nil?
    return "&nbsp;" if value.to_s.empty?
    return value
  end

  # Overrides AbilityHelper.render_visibility_link to fix bug reported in
  # UMRDR issue 727: Link provided by render_visibility_link method had
  # path that displays a form to edit all attributes for a document. New
  # method simply renders the visibility_badge for the document.
  def render_visibility_link(document)
    visibility_badge(document.visibility)
  end

  # A Blacklight index field helper_method
  # @param [Hash] options from blacklight helper_method invocation. Maps rights statement URIs to links with labels.
  # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
  def rights_license_links(options)
    service = Hyrax::RightsLicenseService.new
    to_sentence(options[:value].map { |right| link_to service.label(right), right })
  end

  def t_uri(key, scope: [])
    new_scope = scope.collect do |arg|
      if arg.is_a?(String)
        arg.tr('.', '_')
      else
        arg
      end
    end
    I18n.t(key, scope: new_scope)
  end

end
