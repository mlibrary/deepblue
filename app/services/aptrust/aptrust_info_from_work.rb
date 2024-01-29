# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustInfoFromWork < Aptrust::AptrustInfo

  mattr_accessor :aptrust_info_from_work_debug_verbose, default: false

  CREATOR_JOIN     = ' & ' unless const_defined? :CREATOR_JOIN
  DESCRIPTION_JOIN = ' '   unless const_defined? :DESCRIPTION_JOIN
  TITLE_JOIN       = ' '   unless const_defined? :TITLE_JOIN

  def initialize( work:,
                  aptrust_config: nil,
                  access: nil,
                  creator: nil,
                  description: nil,
                  item_description: nil,
                  storage_option: nil,
                  title: nil )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_info_from_work_debug_verbose
    super( aptrust_config:   aptrust_config,
           access:           ::Aptrust.arg_init_squish( access,           DEFAULT_ACCESS ),
           creator:          ::Aptrust.arg_init_squish( creator,          Array( work.creator ).join( CREATOR_JOIN ) ),
           description:      ::Aptrust.arg_init_squish( description,      DEFAULT_DESCRIPTION ),
           item_description: ::Aptrust.arg_init_squish( item_description, Array( work.description ).join( DESCRIPTION_JOIN ) ),
           storage_option:   ::Aptrust.arg_init(        storage_option,
                                                      ::Aptrust::AptrustInfo.default_storage( aptrust_config: aptrust_config ) ),
           title:            ::Aptrust.arg_init_squish( title,            Array( work.title ).join(TITLE_JOIN ) ) )
  end

end
