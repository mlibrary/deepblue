# json.extract! doc, :id,
#              :title_tesim

# json.doc_class_name doc.class.name
json.model doc["has_model_ssim"].first
json.id doc.id
json.metadata @presenter.metadata_browse( doc )
