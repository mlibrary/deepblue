require 'rails_helper'

RSpec.describe "job_statuses/edit", type: :view, skip: true do
  before(:each) do
    @job_status = assign(:job_status, JobStatus.create!())
  end

  it "renders the edit job_status form" do
    render

    assert_select "form[action=?][method=?]", job_status_path(@job_status), "post" do
    end
  end
end
