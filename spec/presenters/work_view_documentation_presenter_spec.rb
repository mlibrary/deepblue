require 'rails_helper'

class TestWorkViewPresenter < WorkViewDocumentationPresenter
end

RSpec.describe WorkViewDocumentationPresenter do
  let(:admin_set) do
    mock_model(AdminSet,
               id: '123',
               description: ['An example admin set.'],
               title: ['Example Admin Set Title'])
  end

  let(:work) { build(:work, id: "abc", title: ['Example Work Title']) }
  let(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  let(:ability) { double }
  let(:dummy_class) { double }

  it "sets the work object" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    dc = presenter.current_work= work

    expect(dc).to eq(work)
  end

  it "returns of current user is editor" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(ability).to receive(:can?).and_return true 
    allow(presenter).to receive(:solr_document).and_return 1  
    dc = presenter.editor?

    expect(dc).to eq(true)
  end

  it "gets the list of file ids for a work" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
        dc = presenter.current_work= work
    allow(presenter).to receive(:member_presenters).and_return ["1", "2"]  
    dc = presenter.list_of_item_ids_to_display

    expect(dc).to eq([])
  end

  it "returns list of ids" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(presenter).to receive(:member_presenters).and_return ["1", "2"]  
    dc = presenter.member_presenters_for ["1", "2"]

    expect(dc).to eq(["1", "2"])
  end

  it "returns member presenter factor" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(Hyrax::MemberPresenterFactory).to receive(:new).and_return ["1", "2"]
    allow(SolrDocument).to receive(:find).and_return dummy_class
    dc = presenter.current_work=(work)  
    dc = presenter.member_presenter_factory

    expect(dc).to eq(["1", "2"])
  end

  it "shows path to collection" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(dummy_class).to receive(:id).and_return "abc"
    dc = presenter.show_path_collection collection: dummy_class

    expect(dc).to eq("/concern/collections/abc?locale=en")
  end

  it "shows path to data set" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(dummy_class).to receive(:id).and_return "abc"
    dc = presenter.show_path_data_set work: dummy_class

    expect(dc).to eq("/concern/data_sets/abc?locale=en")
  end

  it "gets solr document" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(SolrDocument).to receive(:find).and_return "document"
    dc = presenter.current_work=(work) 
    dc = presenter.solr_document

    expect(dc).to eq("document")
  end

  it "gets the workflow" do
    presenter = TestWorkViewPresenter.new controller: dummy_class, current_ability: ability
    allow(Hyrax::WorkflowPresenter).to receive(:new).and_return "workflow"
    allow(SolrDocument).to receive(:find).and_return "document"
    dc = presenter.current_work=(work)    
    dc = presenter.workflow

    expect(dc).to eq("workflow")
  end

end
