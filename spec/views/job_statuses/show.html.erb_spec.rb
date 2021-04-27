require 'rails_helper'

RSpec.describe "job_statuses/show", type: :view, skip: true do
  before(:each) do
    @job_status = assign(:job_status, JobStatus.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
