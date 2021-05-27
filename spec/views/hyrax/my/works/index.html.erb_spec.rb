require 'rails_helper'

RSpec.describe 'hyrax/my/works/index.html.erb', type: :view do
  let(:resp) { double(docs: "", total_count: 11) }

  let(:add_batch) { t(:'helpers.action.batch.new') }
  let(:add_work) { t(:'helpers.action.work.new') }
  let(:subscribe_analytics) { t('simple_form.actions.data_set.analytics_subscribe') }
  let(:unsubcribe_analytics) { t('simple_form.actions.data_set.analytics_unsubscribe') }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:admin?).and_return false
    allow(view).to receive(:provide).and_yield
    allow(view).to receive(:provide).with(:page_title, String)
    allow(view).to receive(:rss_feed_link_tag).with(any_args).and_return ''
    allow(view).to receive(:atom_feed_link_tag).with(any_args).and_return ''
    assign(:create_work_presenter, presenter)
    assign(:response, resp)
    allow(view).to receive(:can?).and_return(true)
    allow(Flipflop).to receive(:batch_upload?).and_return(batch_enabled)
    allow(Flipflop).to receive(:disable_desposits_and_edits?).and_return(disable_desposits_and_edits)
    stub_template 'shared/_select_work_type_modal.html.erb' => 'modal'
    stub_template 'hyrax/my/works/_tabs.html.erb' => 'tabs'
    stub_template 'hyrax/my/works/_search_header.html.erb' => 'search'
    stub_template 'hyrax/my/works/_document_list.html.erb' => 'list'
    stub_template 'hyrax/my/works/_results_pagination.html.erb' => 'pagination'
    stub_template 'hyrax/my/works/_scripts.js.erb' => 'batch edit stuff'
    assign(:managed_works_count, 1)
  end

  context "when the user can add works" do
    let(:ability) { instance_double(Ability, can_create_any_work?: true) }

    context 'with many presenters' do
      let(:batch_enabled) { true }
      let(:disable_desposits_and_edits) { false }
      let(:presenter) do
        instance_double(
          Deepblue::SelectTypeListPresenter,
          many?: false,
          first_model: DataSet
        )
      end
      before do
        allow(presenter).to receive(:can_subscribe_to_analytics_reports?).and_return true
        allow(presenter).to receive(:analytics_subscribed?).and_return false
      end

      it 'the line item displays the work and its actions' do
        render
        expect(rendered).to have_selector('h1', text: 'Works')
        expect(rendered).to have_link(subscribe_analytics)
        expect(rendered).to have_link(add_batch)
        expect(rendered).to have_link(add_work)
      end

      context 'with batch_upload off' do
        let(:batch_enabled) { false }

        it 'hides batch creation button' do
          render
          expect(rendered).to have_link(subscribe_analytics)
          expect(rendered).to_not have_link(add_batch)
          expect(rendered).to have_link(add_work)
        end
      end

      context 'with disable_desposits_and_edits on' do
        let(:disable_desposits_and_edits) { true }

        it 'hides add new work and batch upload' do
          render
          expect(rendered).to_not have_link(subscribe_analytics)
          expect(rendered).to_not have_link(add_batch)
          expect(rendered).to_not have_link(add_work)
        end
      end
    end

    # GH-929
    context 'without many presenters' do
      let(:batch_enabled) { true }
      let(:disable_desposits_and_edits) { false }
      let(:presenter) do
        instance_double(
          Deepblue::SelectTypeListPresenter,
          many?: false,
          first_model: DataSet
        )
      end
      before do
        allow(presenter).to receive(:can_subscribe_to_analytics_reports?).and_return true
        allow(presenter).to receive(:analytics_subscribed?).and_return false
      end

      it 'the line item displays the work and its actions' do
        render
        expect(rendered).to have_selector('h1', text: 'Works')
        expect(rendered).to have_link(subscribe_analytics)
        expect(rendered).to have_link(add_batch)
        expect(rendered).to have_link(add_work)
      end

      context 'with batch_upload off' do
        let(:batch_enabled) { false }

        it 'hides batch creation button' do
          render
          expect(rendered).to have_link(subscribe_analytics)
          expect(rendered).to_not have_link(add_batch)
          expect(rendered).to have_link(add_work)
        end
      end

      context 'with disable_desposits_and_edits on' do
        let(:disable_desposits_and_edits) { true }

        it 'hides add new work and batch upload' do
          render
          expect(rendered).to_not have_link(subscribe_analytics)
          expect(rendered).to_not have_link(add_batch)
          expect(rendered).to_not have_link(add_work)
        end
      end

    end
  end
end
