# frozen_string_literal: true
# TODO: hyrax v3 upgrade review
@curation_concern = Wings::ActiveFedoraConverter.convert(resource: @curation_concern) if
  @curation_concern.is_a? Hyrax::Resource

json.extract! @curation_concern, *@presenter.json_metadata_properties

json.extract! @curation_concern, :file_set_ids

json.file_sets do
  json.array! @presenter.member_presenter_factory.file_set_presenters.each do |fsp|
    # json.id fsp.id
    json.partial! 'hyrax/file_sets/show', locals: { file_set_presenter: fsp }
  end
end
json.version @curation_concern.etag
