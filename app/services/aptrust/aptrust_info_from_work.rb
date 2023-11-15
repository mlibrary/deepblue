# frozen_string_literal: true

module Aptrust

  class AptrustInfoFromWork < AptrustInfo

    mattr_accessor :aptrust_info_debug_verbose, default: true

    CREATOR_JOIN = ' & '
    DESCRIPTION_JOIN = ' '
    TITLE_JOIN = ' '

    def initialize( work:,
                    access: nil,
                    creator: nil,
                    description: nil,
                    item_description: nil,
                    storage_option: nil,
                    title: nil )

      super( access:           AptrustBehavior.arg_init_squish( access,           DEFAULT_ACCESS ),
             creator:          AptrustBehavior.arg_init_squish( creator,          Array( work.creator ).join( CREATOR_JOIN ) ),
             description:      AptrustBehavior.arg_init_squish( description,      DEFAULT_DESCRIPTION ),
             item_description: AptrustBehavior.arg_init_squish( item_description, Array( work.description ).join( DESCRIPTION_JOIN ) ),
             storage_option:   AptrustBehavior.arg_init_squish( storage_option,   DEFAULT_STORAGE_OPTION ),
             title:            AptrustBehavior.arg_init_squish( title,            Array( work.title ).join(TITLE_JOIN ) ) )
    end

  end

end
