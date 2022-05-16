# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_permission_form.html.erb', type: :view do
  let(:file_set) do
    stub_model(FileSet, id: '123',
                        depositor: 'bob',
                        resource_type: ['Dataset'])
  end

  let(:form) do
    view.simple_form_for(file_set, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    # allow( view ).to receive( :presenter ).and_return( presenter )
    # assign( :presenter, presenter )
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    # allow(view).to receive(:f).and_return(form)
    assign( :f, form )
    @f = form
    allow(file_set).to receive(:permissions).and_return(permissions)
    view.lookup_context.prefixes.push 'hyrax/base'
    stub_template "_currently_shared.html.erb" => "<span class='base-currently-shared'>base/currently_shared</span>"
    view.extend Hyrax::PermissionsHelper
    @curation_concern = file_set
    render 'hyrax/file_sets/permission_form', file_set: file_set, f: form
  end

  context "without additional users" do
    let(:permissions) { [] }

    it "draws the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).not_to have_css("button.remove_perm")
    end
  end

  context "with additional users", skip: true do
    # TODO: fix - hyrax v3
    let(:depositor_permission) { Hydra::AccessControls::Permission.new(id: '123', name: 'bob', type: 'person', access: 'edit') }
    let(:public_permission) { Hydra::AccessControls::Permission.new(id: '124', name: 'public', type: 'group', access: 'read') }
    let(:other_permission) { Hydra::AccessControls::Permission.new(id: '125', name: 'joe@example.com', type: 'person', access: 'edit') }
    let(:permissions) { [depositor_permission, public_permission, other_permission] }

    it "draws the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).to have_css("button.remove_perm", count: 1) # depositor and public should be filtered out
      expect(rendered).to have_css("button.remove_perm[data-index='2']")
    end
  end

end
