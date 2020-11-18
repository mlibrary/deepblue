require 'rails_helper'

RSpec.describe '/_user_util_links.html.erb', type: :view do
  let(:join_date) { 5.days.ago }

  context "standard depositor" do

    before do
      allow(view).to receive(:user_signed_in?).and_return true
      allow(view).to receive(:current_user).and_return stub_model(User, user_key: 'userX')
      allow(view).to receive(:can?).with(:create, DataSet).and_return true
      allow(view).to receive(:can?).with(:manage, User).and_return false
      allow(view).to receive(:can?).with(:review, :submissions).and_return false
      allow(view).to receive(:can?).with(:read, :admin_dashboard).and_return false
    end

    it 'has dropdown list of links' do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect( page ).to have_link 'userX', href: hyrax.dashboard_profile_path('userX')
      expect( rendered ).to have_link t('hyrax.toolbar.dashboard.menu'), href: hyrax.dashboard_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.collections'), href: hyrax.my_collections_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.works'), href: hyrax.my_works_path

      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.workflow_review'), href: hyrax.admin_workflows_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.google_analytics'),
                                          href: main_app.google_analytics_dashboard_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.users'), href: hyrax.admin_users_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.documentation'),
                                          href: main_app.work_view_documentation_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.manage_email'), href: main_app.email_dashboard_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.manage_embargoes'), href: hyrax.embargoes_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.provenance_log'), href: main_app.scheduler_dashboard_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.scheduler'), href: main_app.scheduler_dashboard_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.users'), href: main_app.persona_users_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.resque_web'),
                                          href: Rails.application.routes.url_helpers.resque_web_path
      expect( rendered ).not_to have_link t('hyrax.admin.sidebar.technical'), href: hyrax.admin_features_path

      expect( rendered ).to have_link t("hyrax.toolbar.profile.logout"), href: main_app.destroy_user_session_path
      expect( rendered ).to have_content t("hyrax.toolbar.profile.logout")
    end

    it 'shows the number of outstanding messages' do
      render
      expect( rendered ).to have_selector "a[aria-label='You have no unread notifications'][href='#{hyrax.notifications_path}']"
      expect( rendered ).to have_selector 'a.notify-number span.label-default.invisible', text: '0'
    end

    describe 'translations' do
      # TODO: investigate why this fails
      # context 'with two languages' do
      #   before do
      #     allow(view).to receive(:available_translations) { { 'en' => 'English', 'es' => 'Español' } }
      #     render
      #   end
      #   it 'displays the current language' do
      #     expect(rendered).to have_link('English')
      #   end
      # end
      context 'with one language' do
        before do
          allow(view).to receive(:available_translations) { { 'en' => 'English' } }
          render
        end
        it 'does not display the language picker' do
          expect(rendered).not_to have_link('English')
        end
      end
    end

  end

  context "admin" do

    before do
      allow(view).to receive(:user_signed_in?).and_return true
      allow(view).to receive(:current_user).and_return stub_model(User, user_key: 'userX')
      allow(view).to receive(:can?).with(:create, DataSet).and_return true
      allow(view).to receive(:can?).with(:manage, User).and_return true
      allow(view).to receive(:can?).with(:review, :submissions).and_return true
      allow(view).to receive(:can?).with(:read, :admin_dashboard).and_return true
    end

    it 'has dropdown list of links' do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect( page ).to have_link 'userX', href: hyrax.dashboard_profile_path('userX')
      expect( rendered ).to have_link t('hyrax.toolbar.dashboard.menu'), href: hyrax.dashboard_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.collections'), href: hyrax.my_collections_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.works'), href: hyrax.my_works_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.workflow_review'), href: hyrax.admin_workflows_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.google_analytics'),
                                          href: main_app.google_analytics_dashboard_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.users'), href: hyrax.admin_users_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.documentation'),
                                          href: main_app.work_view_documentation_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.manage_email'), href: main_app.email_dashboard_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.manage_embargoes'), href: hyrax.embargoes_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.scheduler'), href: main_app.scheduler_dashboard_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.users'), href: main_app.persona_users_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.provenance_log'), href: main_app.provenance_log_path
      expect( rendered ).to have_link t('hyrax.admin.sidebar.resque_web'),
                                          href: Rails.application.routes.url_helpers.resque_web_path
      expect( rendered ).to have_content t('hyrax.admin.sidebar.technical')
      expect( rendered ).to have_link t('hyrax.admin.sidebar.technical'), href: hyrax.admin_features_path
      expect( rendered ).to have_link t("hyrax.toolbar.profile.logout"), href: main_app.destroy_user_session_path
      expect( rendered ).to have_content t("hyrax.toolbar.profile.logout")
    end

    it 'shows the number of outstanding messages' do
      render
      expect( rendered ).to have_selector "a[aria-label='You have no unread notifications'][href='#{hyrax.notifications_path}']"
      expect( rendered ).to have_selector 'a.notify-number span.label-default.invisible', text: '0'
    end

    describe 'translations' do
      # TODO: investigate why this fails
      # context 'with two languages' do
      #   before do
      #     allow(view).to receive(:available_translations) { { 'en' => 'English', 'es' => 'Español' } }
      #     render
      #   end
      #   it 'displays the current language' do
      #     expect(rendered).to have_link('English')
      #   end
      # end
      context 'with one language' do
        before do
          allow(view).to receive(:available_translations) { { 'en' => 'English' } }
          render
        end
        it 'does not display the language picker' do
          expect(rendered).not_to have_link('English')
        end
      end
    end

  end

end
