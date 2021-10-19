# frozen_string_literal: true
require 'rails_helper'

describe 'Hyrax::Doi::WorkFormHelper', skip: true do
  describe 'render_doi?' do
    let(:doi_presenter_class) do
      Class.new(Hyrax::GenericWorkPresenter) do
        include Hyrax::Doi::DoiPresenterBehavior
      end
    end
    let(:datacite_presenter_class) do
      Class.new(Hyrax::GenericWorkPresenter) do
        include Hyrax::Doi::DoiPresenterBehavior
        include Hyrax::Doi::DataCiteDoiPresenterBehavior
      end
    end
    let(:non_doi_presenter_class) { Hyrax::GenericWorkPresenter }
    let(:solr_document_class) do
      Class.new(SolrDocument) do
        include Hyrax::Doi::SolrDocument::DoiBehavior
        include Hyrax::Doi::SolrDocument::DataCiteDoiBehavior
      end
    end
    let(:presenter) { presenter_class.new(solr_document, nil, nil) }
    let(:solr_document) { instance_double(solr_document_class) }

    # Override rspec-rails defined helper
    # This allow us to inject HyraxHelper which is being overriden
    # so super is defined.
    let(:helper) do
      _view.tap do |v|
        v.extend(ApplicationHelper)
        v.extend(HyraxHelper)
        v.extend(Hyrax::Doi::HelperBehavior)
        v.assign(view_assigns)
      end
    end

    context 'with a DOI-enabled model' do
      let(:presenter_class) { doi_presenter_class }

      it 'returns true' do
        expect(helper.render_doi?(presenter)).to eq true
      end
    end

    context 'with a DataCite DOI-enabled presenter' do
      let(:presenter_class) { datacite_presenter_class }

      context 'with findable doi status' do
        before do
          allow(solr_document).to receive(:doi_status_when_public).and_return('findable')
        end

        it 'returns true' do
          expect(helper.render_doi?(presenter)).to eq true
        end
      end

      context 'with draft doi status' do
        before do
          allow(solr_document).to receive(:doi_status_when_public).and_return('draft')
        end

        it 'returns false' do
          expect(helper.render_doi?(presenter)).to eq false
        end
      end

      context 'with doi status not set' do
        before do
          allow(solr_document).to receive(:doi_status_when_public).and_return(nil)
        end

        it 'returns true' do
          expect(helper.render_doi?(presenter)).to eq true
        end
      end
    end

    context 'with a non-DOI-enabled model' do
      let(:presenter_class) { non_doi_presenter_class }

      it 'returns false' do
        expect(helper.render_doi?(presenter)).to eq false
      end
    end
  end
end
