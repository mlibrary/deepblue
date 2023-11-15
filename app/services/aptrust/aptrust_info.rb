# frozen_string_literal: true

module Aptrust

  class AptrustInfo

    DEFAULT_ACCESS = 'Institution'
    DEFAULT_CREATOR = ''
    DEFAULT_DESCRIPTION = 'No description.'
    DEFAULT_ITEM_DESCRIPTION = 'No item description.'
    DEFAULT_STORAGE_OPTION = 'Standard'
    DEFAULT_TITLE = 'No Title'

    attr_accessor :access
    attr_accessor :creator
    attr_accessor :description
    attr_accessor :item_description
    attr_accessor :storage_option
    attr_accessor :title

    def initialize( access: nil,
                    creator: nil,
                    description: nil,
                    item_description: nil,
                    storage_option: nil,
                    title: nil )

      @access           = AptrustBehavior.arg_init_squish( access,           DEFAULT_ACCESS )
      @creator          = AptrustBehavior.arg_init_squish( creator,          DEFAULT_CREATOR )
      @description      = AptrustBehavior.arg_init_squish( description,      DEFAULT_DESCRIPTION )
      @item_description = AptrustBehavior.arg_init_squish( item_description, DEFAULT_ITEM_DESCRIPTION )
      @storage_option   = AptrustBehavior.arg_init_squish( storage_option,   DEFAULT_STORAGE_OPTION )
      @title            = AptrustBehavior.arg_init_squish( title,            DEFAULT_TITLE )
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

end
