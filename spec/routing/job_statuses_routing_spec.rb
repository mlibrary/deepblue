require "rails_helper"

RSpec.describe JobStatusesController, type: :routing, skip: true do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/job_statuses").to route_to("job_statuses#index")
    end

    it "routes to #new" do
      expect(get: "/job_statuses/new").to route_to("job_statuses#new")
    end

    it "routes to #show" do
      expect(get: "/job_statuses/1").to route_to("job_statuses#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/job_statuses/1/edit").to route_to("job_statuses#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/job_statuses").to route_to("job_statuses#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/job_statuses/1").to route_to("job_statuses#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/job_statuses/1").to route_to("job_statuses#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/job_statuses/1").to route_to("job_statuses#destroy", id: "1")
    end
  end
end
