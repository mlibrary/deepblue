require 'rails_helper'

describe SearchBuilder do # rubocop:disable RSpec/EmptyExampleGroup

  subject(:search_builder) { described_class.new scope }
  let(:user_params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }

  describe "my custom step" do # rubocop:disable RSpec/EmptyExampleGroup
    # subject(:query_parameters) do
    #   search_builder.with(user_params).processed_parameters
    # end
    #
    # it "adds my custom data" do
    #   expect(query_parameters).to include :custom_data
    # end
  end

end
