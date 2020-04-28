json.extract!( @presenter, *@presenter.json_metadata_properties )

json.collection_members do
  json.array! @presenter.collection_members_of_this_collection.each do |work|
    json.extract! work, :id, :title
  end
end

json.collection_works do
  json.array! @presenter.work_members_of_this_collection.each do |work|
    json.extract! work, :id, :title
  end
end

