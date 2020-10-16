FactoryBot.define do

  factory :job_status, class: JobStatus do

    job_id    { 'job-id-1234' }
    job_class { 'JobClassName' }

    factory :job_status_started do
      status { JobStatus::STARTED }
    end

    factory :job_status_finished, class: JobStatus do
      status { JobStatus::FINISHED }
    end

  end

end
