require 'rails_helper'

RSpec.describe Hyrax::CitationsBehaviors::Formatters::MlaFormatter, skip: false do
  subject(:formatter) { described_class.new(:no_context) }

  let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(work.to_solr), :no_ability) }
  let(:work)      { build(:data_set, title: ['<ScrIPt>prompt("Confirm Password")</sCRIpt>']) }

  it 'sanitizes input' do
    expect(formatter.format(presenter).downcase).not_to include '<ScrIPt>prompt'.downcase
  end

  describe '.format_authors' do

    context 'without commas' do
      it { expect(subject.format_authors ).to eq '' }
      it { expect(subject.format_authors( ['Name']) ).to eq 'Name.' }
      it { expect(subject.format_authors( ['Alpha', 'Beta']) ).to eq 'Alpha, Beta.' }
      it { expect(subject.format_authors( ['First Last']) ).to eq 'First Last.' }
      it { expect(subject.format_authors( ['First Last', 'First2 Last2']) ).to eq 'First Last, First2 Last2.' }
    end

    context 'without commas and padded with spaces' do
      it { expect(subject.format_authors ).to eq '' }
      it { expect(subject.format_authors( ['Name  ']) ).to eq 'Name.' }
      it { expect(subject.format_authors( [' Alpha', 'Beta']) ).to eq 'Alpha, Beta.' }
      it { expect(subject.format_authors( [' First Last ']) ).to eq 'First Last.' }
      it { expect(subject.format_authors( ['  First Last ', 'First2 Last2']) ).to eq 'First Last, First2 Last2.' }
    end

    context 'with commas' do
      it { expect(subject.format_authors( ['Last, First']) ).to eq 'Last, F.' }
      it { expect(subject.format_authors( ['Last, First', 'Alpha, Beta']) ).to eq 'Last, F., Alpha, B.' }
    end

    context 'mixed' do
      it { expect(subject.format_authors( ['Last, First', 'Alpha Beta']) ).to eq 'Last, F., Alpha Beta.' }
    end

  end

  describe '.format_date' do

    it { expect(subject.format_date( 'Whatever the input is') ).to eq 'Whatever the input is' }

  end

  describe '.format_doi' do

    it { expect(subject.format_doi( [] ) ).to eq '' }
    it { expect(subject.format_doi( ['doi:xyz'] ) ).to eq 'https://doi.org/xyz' }

  end

  describe '.format_title' do

    context 'title is unmodified' do
      it { expect(subject.format_title( 'Title') ).to eq "<span class='citation-title'>Title</span> "  }
      it { expect(subject.format_title( 'title') ).to eq "<span class='citation-title'>title</span> " }
      it { expect(subject.format_title( 'A Longer Title') ).to eq "<span class='citation-title'>A Longer Title</span> " }
    end

    context 'title has colons' do
      it { expect(subject.format_title( 'Title: Subtitle') ).to eq "<span class='citation-title'>Title&#58; Subtitle</span> " }
    end

    context 'title has trailing period' do
      it { expect(subject.format_title( 'Title.') ).to eq "<span class='citation-title'>Title</span> " }
      it { expect(subject.format_title( 'title.') ).to eq "<span class='citation-title'>title</span> " }
      it { expect(subject.format_title( 'A Longer Title.') ).to eq "<span class='citation-title'>A Longer Title</span> " }
    end

    context 'title is an array' do
      it { expect(subject.format_title( ['Title']) ).to eq "<span class='citation-title'>Title</span> " }
      it { expect(subject.format_title( ['Title', 'title part two']) ).to eq "<span class='citation-title'>Title title part two</span> " }
    end

    context 'combined' do
      it { expect(subject.format_title( 'Title: Subtitle.') ).to eq "<span class='citation-title'>Title&#58; Subtitle</span> " }
    end

  end

  describe '.to_timestamp' do
    let(:date_published) { DateTime.new(2020,1,1) }
    it { expect(subject.to_timestamp(date_published)).to eq date_published }
    it { expect(subject.to_timestamp(date_published.to_s)).to eq date_published.to_s }
    it { expect(subject.to_timestamp(Array(date_published))).to eq date_published.to_s }
  end

  describe '.format_year' do

    context 'normal year' do
      let(:date_published) { DateTime.new(2020,1,1) }
      let(:work) { build(:work, creator: ["Doctor Creator"], title: ['The Title'], date_published: date_published )}
      it { expect(subject.format_year(work)).to eq 2020 }
    end

  end

  describe '.format' do

    context 'work with creator and title' do
      let(:work) { build(:work, creator: ["Doctor Creator"], title: ['The Title'] )}
      it { expect(subject.format(work) ).to eq "<span class='citation-author'>Doctor Creator.</span> <span class='citation-title'>The Title</span> [Data set]. University of Michigan - Deep Blue. " }
    end

    context 'work with creator and title and date published' do
      let(:date_published) { DateTime.new(2020,1,1) }
      let(:work) { build(:work, creator: ["Doctor Creator"], title: ['The Title'], date_published: date_published )}
      before do
        expect(work.date_published.is_a?(DateTime)).to eq true
      end
      it { expect(subject.format(work) ).to eq "<span class='citation-author'>Doctor Creator.</span> <span class='citation-title'>The Title</span> [Data set], (2020). University of Michigan - Deep Blue. " }
    end

    context 'work with creator and title and date published' do
      let(:date_published) { DateTime.new(2020,1,1) }
      let(:work) { build(:work, creator: ["Doctor Creator"], title: ['The Title'] )}
      before do
        allow(work).to receive(:date_published).and_return [date_published]
      end
      it { expect(subject.format(work) ).to eq "<span class='citation-author'>Doctor Creator.</span> <span class='citation-title'>The Title</span> [Data set], (2020). University of Michigan - Deep Blue. " }
    end

  end

end
