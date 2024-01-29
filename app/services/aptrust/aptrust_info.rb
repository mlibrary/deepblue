# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustInfo

  mattr_accessor :aptrust_info_debug_verbose, default: false

  DEFAULT_ACCESS           = 'Institution'          unless const_defined? :DEFAULT_ACCESS
  DEFAULT_CREATOR          = ''                     unless const_defined? :DEFAULT_CREATOR
  DEFAULT_DESCRIPTION      = 'No description.'      unless const_defined? :DEFAULT_DESCRIPTION
  DEFAULT_ITEM_DESCRIPTION = 'No item description.' unless const_defined? :DEFAULT_ITEM_DESCRIPTION
  DEFAULT_STORAGE_OPTION   = 'Standard'             unless const_defined? :DEFAULT_STORAGE_OPTION
  DEFAULT_TITLE            = 'No Title'             unless const_defined? :DEFAULT_TITLE

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
    rv = aptrust_config.blank? ? DEFAULT_STORAGE_OPTION : aptrust_config.storage_option
    rv ||= DEFAULT_STORAGE_OPTION
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
    @access           = ::Aptrust.arg_init_squish( access,           DEFAULT_ACCESS )
    @creator          = ::Aptrust.arg_init_squish( creator,          DEFAULT_CREATOR )
    @description      = ::Aptrust.arg_init_squish( description,      DEFAULT_DESCRIPTION )
    @item_description = ::Aptrust.arg_init_squish( item_description, DEFAULT_ITEM_DESCRIPTION )
    @storage_option   = ::Aptrust.arg_init(        storage_option,
                                                 ::Aptrust::AptrustInfo.default_storage( aptrust_config: aptrust_config ) )
    @title            = ::Aptrust.arg_init_squish( title,            DEFAULT_TITLE )
  end

  def build
    <<~INFO
      Title: #{title}
      Access: #{access}
      Storage-Option: #{storage_option}
      Description: #{description}
      Item Description: #{item_description}
      Creator/Author: #{creator}
    INFO
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
