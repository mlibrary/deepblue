# frozen_string_literal: true

RSpec.describe Hyrax::Orcid::Blacklight::Rendering::PipelineJsonExtractor, skip: true do
  let(:document) { instance_double(SolrDocument) }
  let(:context) { double }
  let(:options) { double }
  let(:terminator) { Blacklight::Rendering::Terminator }
  let(:presenter) { described_class.new(values, field_config, document, context, options, [terminator]) }
  let(:values) do
    [
      [
        {
          "creator_name" => creator1,
          "creator_orcid" => "0000-1234-5678-9000"
        },
        {
          "creator_name" => creator2,
          "creator_orcid" => "1234-1234-1234-1234"
        }
      ].to_json
    ]
  end
  let(:creator1) { "John Smith" }
  let(:creator2) { "Joanne Htims" }
  let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: "creator") }

  describe "render" do
    subject { presenter.render }

    context "when is a creator field" do
      it "returns an array of creator names" do
        expect(subject).to eq([creator1, creator2])
      end
    end

    context "when is a contributor field" do
      let(:values) do
        [
          [
            {
              "contributor_name" => contributor1,
              "contributor_orcid" => "0000-1234-5678-9000"
            },
            {
              "contributor_name" => contributor2,
              "contributor_orcid" => "1234-1234-1234-1234"
            }
          ].to_json
        ]
      end
      let(:contributor1) { "John Smith" }
      let(:contributor2) { "Joanne Htims" }
      let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: "contributor") }

      it "returns an array of contributor names" do
        expect(subject).to eq([contributor1, contributor2])
      end
    end

    context "when is not a JSON field" do
      let(:values) { ["Not JSON"] }
      let(:field_config) { Blacklight::Configuration::NullField.new(itemprop: "another_field") }

      it "returns an array of contributor names" do
        expect(subject).to eq(values)
      end
    end
  end

  describe "#operations" do
    subject { Blacklight::Rendering::Pipeline.operations }

    it { is_expected.to include(described_class) }
  end
end
