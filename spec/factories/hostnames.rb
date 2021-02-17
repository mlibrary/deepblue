FactoryBot.define do

  factory :hostnames_allowed, class: Array do
    initialize_with { [ ::DeepBlueDocs::Application.config.hostname,
                        'deepblue.lib.umich.edu',
                        'staging.deepblue.lib.umich.edu',
                        'testing.deepblue.lib.umich.edu' ] }
  end

  factory :hostnames_not_allowed, class: Array do
    initialize_with { [ 'deepblue.lib.umich.edu',
                        'staging.deepblue.lib.umich.edu',
                        'testing.deepblue.lib.umich.edu' ] }
  end

end
