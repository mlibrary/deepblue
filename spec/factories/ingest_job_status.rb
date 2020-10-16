FactoryBot.define do

  factory :ingest_job_status do

    job_id     { 'job-id-1234' }
    job_status { create( :job_status ) }

  end

end
