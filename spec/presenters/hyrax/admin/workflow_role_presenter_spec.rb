# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Admin::WorkflowRolePresenter, skip: false do
  let(:presenter) { described_class.new(workflow_role) }
  let(:role) { Sipity::Role[:depositor] }
  let(:workflow) { create(:workflow) }
  let(:workflow_role) { Sipity::WorkflowRole.new(role: role, workflow: workflow) }

  describe '#label' do
    subject { presenter.label }

    it { is_expected.to be_a(String) }
  end
end
