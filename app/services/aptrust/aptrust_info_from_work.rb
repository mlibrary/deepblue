# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustInfoFromWork < Aptrust::AptrustInfo

  mattr_accessor :aptrust_info_from_work_debug_verbose, default: false

  mattr_accessor :dbd_creator,      default: ::Aptrust::AptrustIntegrationService.dbd_creator
  mattr_accessor :work_description, default: ::Aptrust::AptrustIntegrationService.dbd_work_description

  ITEM_DESCRIPTION_JOIN = ' '   unless const_defined? :ITEM_DESCRIPTION_JOIN
  TITLE_JOIN            = ' '   unless const_defined? :TITLE_JOIN

  def dbd_work_description( work_description )
    description = work_description.dup
    description.gsub!( '%work_type%', 'DataSet' )
    return description
  end

  def initialize( work:,
                  aptrust_config: nil,
                  access: nil,
                  creator: ::Aptrust::AptrustInfoFromWork.dbd_creator,
                  description: ::Aptrust::AptrustInfoFromWork.work_description,
                  item_description: nil,
                  storage_option: nil,
                  title: nil )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_info_from_work_debug_verbose
    super( aptrust_config:   aptrust_config,
           access:           ::Aptrust.arg_init_squish( access,           ::Aptrust::AptrustInfo.default_access ),
           creator:          ::Aptrust.arg_init(        creator,          ::Aptrust::AptrustInfoFromWork.dbd_creator ),
           description:      ::Aptrust.arg_init_squish( dbd_work_description( description ),
                                                        ::Aptrust::AptrustInfoFromWork.work_description ),
           item_description: ::Aptrust.arg_init_squish( item_description,
                                                        Array( work.description ).join( ITEM_DESCRIPTION_JOIN ) ),
           storage_option:   ::Aptrust.arg_init(        storage_option,
                                            ::Aptrust::AptrustInfo.default_storage( aptrust_config: aptrust_config ) ),
           title:            ::Aptrust.arg_init_squish( title,            Array( work.title ).join(TITLE_JOIN ) ) )
  end

  def build_replace( template )
    super( template )
  end

  def build_template
    super
  end

end
