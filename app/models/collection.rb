# frozen_string_literal: true

class Collection < ActiveFedora::Base
  include ::Hyrax::CollectionBehavior

  # You can replace these metadata if they're not suitable
  #include Hyrax::BasicMetadata
  include Umrdr::UmrdrWorkBehavior
  include Umrdr::UmrdrWorkMetadata

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Deepblue::DefaultMetadata

  self.indexer = Hyrax::CollectionWithBasicMetadataIndexer

  # after_initialize :set_defaults
  #
  # def set_defaults
  #   return unless new_record?
  #   # self.visibility = 'open'
  # end

  # begin metadata

  # the list of creators is ordered
  def creator
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: creator_ordered, values: values )
    return values
  end

  def creator=( values )
    self.creator_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: creator_ordered, values: values )
    super values
  end

  # the list of description is ordered
  def description
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: description_ordered, values: values )
    return values
  end

  def description=( values )
    self.description_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: description_ordered, values: values )
    super values
  end

  #
  # handle the list of referenced_by as ordered
  #
  def referenced_by
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: referenced_by_ordered, values: values )
    return values
  end

  def referenced_by=( values )
    self.referenced_by_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: referenced_by_ordered, values: values )
    super values
  end

  #
  # the list of keyword is ordered
  #
  def keyword
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: keyword_ordered, values: values )
    return values
  end

  def keyword=( values )
    self.keyword_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: keyword_ordered, values: values )
    super values
  end

  #
  # handle the list of language as ordered
  #
  def language
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: language_ordered, values: values )
    return values
  end

  def language=( values )
    self.language_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: language_ordered, values: values )
    super values
  end

  # the list of title is ordered
  def title
    values = super
    values = Deepblue::MetadataHelper.ordered( ordered_values: title_ordered, values: values )
    return values
  end

  def title=( values )
    self.title_ordered = Deepblue::MetadataHelper.ordered_values( ordered_values: title_ordered, values: values )
    super values
  end

  # end metadata


end
