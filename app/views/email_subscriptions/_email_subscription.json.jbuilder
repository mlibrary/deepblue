json.extract! email_subscription, :id, :created_at, :updated_at
json.url email_subscription_url(email_subscription, format: :json)
