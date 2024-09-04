# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustInfo

  mattr_accessor :aptrust_info_debug_verbose, default: false

  DEFAULT_APTRUST_INFO_TXT_TEMPLATE =<<-END_OF_TEMPLATE
Title: %title%
Access: %access%
Storage-Option: %storage_option%
Description: %description%
Item Description: %item_description%
Creator/Author: %creator%
END_OF_TEMPLATE

  mattr_accessor :aptrust_info_txt_template, default: ::Aptrust::AptrustIntegrationService.aptrust_info_txt_template

  mattr_accessor :default_access,           default: ::Aptrust::AptrustIntegrationService.default_access
  mattr_accessor :default_creator,          default: ::Aptrust::AptrustIntegrationService.default_creator
  mattr_accessor :default_description,      default: ::Aptrust::AptrustIntegrationService.default_description
  mattr_accessor :default_item_description, default: ::Aptrust::AptrustIntegrationService.default_item_description
  mattr_accessor :default_storage_option,   default: ::Aptrust::AptrustIntegrationService.default_storage_option
  mattr_accessor :default_title,            default: ::Aptrust::AptrustIntegrationService.default_title

  attr_accessor :aptrust_config
  attr_accessor :access
  attr_accessor :creator
  attr_accessor :description
  attr_accessor :item_description
  attr_accessor :storage_option
  attr_accessor :title

  def self.default_storage( aptrust_config: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_info_debug_verbose
    rv = aptrust_config.blank? ? ::Aptrust::AptrustInfo.default_storage_option : aptrust_config.storage_option
    rv ||= ::Aptrust::AptrustInfo.default_storage_option
    rv
  end

  def initialize( aptrust_config: nil,
                  access: nil,
                  creator: nil,
                  description: nil,
                  item_description: nil,
                  storage_option: nil,
                  title: nil )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_info_debug_verbose
    @aptrust_config   = aptrust_config
    @access           = ::Aptrust.arg_init_squish( access,           ::Aptrust::AptrustInfo.default_access )
    @creator          = ::Aptrust.arg_init_squish( creator,          ::Aptrust::AptrustInfo.default_creator )
    @description      = ::Aptrust.arg_init_squish( description,      ::Aptrust::AptrustInfo.default_description )
    @item_description = ::Aptrust.arg_init_squish( item_description, ::Aptrust::AptrustInfo.default_item_description )
    @storage_option   = ::Aptrust.arg_init(        storage_option,
                                                 ::Aptrust::AptrustInfo.default_storage( aptrust_config: aptrust_config ) )
    @title            = ::Aptrust.arg_init_squish( title,            ::Aptrust::AptrustInfo.default_title )
  end

  def build( msg_handler: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if msg_handler.present?
    template = build_template.dup
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "template=#{template}" ] if msg_handler.present?
    template = build_replace( template )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "template=#{template}" ] if msg_handler.present?
    return template
  end

  def build_replace( template, msg_handler: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "title=#{title}" ] if msg_handler.present?
    template.gsub!( '%title%',            title )
    template.gsub!( '%access%',           access )
    template.gsub!( '%storage_option%',   storage_option )
    template.gsub!( '%description%',      description )
    template.gsub!( '%item_description%', item_description )
    template.gsub!( '%creator%',          creator )
    return template
  end

  def build_template
    rv = aptrust_info_txt_template
    rv = DEFAULT_APTRUST_INFO_TXT_TEMPLATE if rv.blank?
    return rv
  end

  def build_fulcrum # save as reference
    # # Add aptrust-info.txt file
    # # this is text that shows up in the APTrust web interface
    # # title, access, and description are required; Storage-Option defaults to Standard if not present
    # monograph_presenter = Sighrax.hyrax_presenter(monograph)
    # title = monograph_presenter.title.blank? ? '' : monograph_presenter.title.squish[0..255]
    # publisher = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..249]
    # press = monograph_presenter.press.blank? ? '' : monograph_presenter.press.squish[0..249]
    # description = monograph_presenter.description.first.blank? ? '' : monograph_presenter.description.first.squish[0..249]
    # creator = monograph_presenter.creator.blank? ? '' : monograph_presenter.creator.first.squish[0..249]
    <<~INFO
      Title: #{title}
      Access: #{institution}
      Storage-Option: #{storage_option}
      Description: #{description}
      Press-Name: #{publisher}
      Press: #{press}
      Item Description: #{description}
      Creator/Author: #{creator}
    INFO
  end

end
