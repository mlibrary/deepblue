require 'rails_helper'

RSpec.describe "job_statuses/index", type: :view, skip: true do
  before(:each) do
    assign(:job_statuses, [
      JobStatus.create!(),
      JobStatus.create!()
    ])
  end

  it "renders a list of job_statuses" do
    render
  end
end
