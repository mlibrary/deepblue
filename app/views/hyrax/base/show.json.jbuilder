json.extract! @curation_concern,
              *[:id] + @curation_concern.class.fields.reject { |f| [:has_model].include? f }
json.extract! @curation_concern, :file_set_ids
json.file_sets do
  json.array! @presenter.member_presenter_factory.file_set_presenters.each do |fsp|
    # json.id fsp.id
    json.partial! 'hyrax/file_sets/show', locals: { file_set_presenter: fsp }
  end
end
json.version @curation_concern.etag
