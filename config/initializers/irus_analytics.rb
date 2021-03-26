# Configuration of IrusAnalytics
env = Rails.env.to_s

IrusAnalytics.configuration.source_repository = case env
when "development"
  "local.deepblue.lib.umich.edu/data"
when "test"
  "testing.deepblue.lib.umich.edu/data"
else
  "deepblue.lib.umich.edu/data"
end

IrusAnalytics.configuration.irus_server_address = case env
when "development"
  nil
when "test"
  nil
else
  "https://irus.jisc.ac.uk/counter/test/"
end
