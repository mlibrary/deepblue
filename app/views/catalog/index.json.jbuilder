json.response do
  # json.docs @presenter.documents
  json.docs do
    json.array! @presenter.documents.each do |doc|
      json.partial! 'catalog/doc', locals: { doc: doc }
    end
  end
  json.facets @presenter.search_facets_as_json
  json.pages @presenter.pagination_info
end
