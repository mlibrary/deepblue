require 'rails_helper'

RSpec.describe ::Deepblue::EmailHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect(described_class.email_helper_debug_verbose).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class::TEXT_HTML ).to eq 'text/html' }
    it { expect( described_class::UTF8      ).to eq 'UTF-8' }
  end

  describe 'I18n translations' do
    let(:key) { 'hyrax.email.deactivate_embargo.subject' }
    let(:title) { 'The Title' }
    let(:expected_translation) { "Deepblue Data: Embargo deactivated for #{title}" }
    it { expect(described_class.t( key, title: title )).to eq expected_translation }
    it { expect(described_class.translate( key, title: title )).to eq expected_translation }
  end

  describe 'Clean strings' do
    let(:utf8_str) { "utf8 string".force_encoding( described_class::UTF8 ) }
    let(:non_utf8_str) { "non-utf8 string".force_encoding('ISO-8859-1') }
    it { expect(described_class.clean_str_needed?(utf8_str)).to eq false }
    it { expect(described_class.clean_str_needed?(non_utf8_str)).to eq true }
    it { expect(described_class.clean_str!(utf8_str.dup).encoding.to_s).to eq described_class::UTF8 }
    it { expect(described_class.clean_str!(non_utf8_str.dup).encoding.to_s).to eq described_class::UTF8 }
    it 'and dups str' do
      clean_str = described_class.clean_str(utf8_str)
      expect(clean_str.encoding.to_s).to eq described_class::UTF8
      expect(clean_str.equal? utf8_str).to eq false
    end
    it 'and dups str' do
      clean_str = described_class.clean_str(non_utf8_str)
      expect(clean_str.encoding.to_s).to eq described_class::UTF8
      expect(clean_str.equal? non_utf8_str).to eq false
    end
  end

  describe '#curation_concern_type' do
    it { expect( described_class.curation_concern_type(curation_concern: build(:data_set))).to eq 'work' }
    it { expect( described_class.curation_concern_type(curation_concern: build(:file_set))).to eq 'file' }
    it { expect( described_class.curation_concern_type(curation_concern: build(:collection))).to eq 'collection' }
    it { expect( described_class.curation_concern_type(curation_concern: "string")).to eq 'unknown' }
    it { expect( described_class.curation_concern_type(curation_concern: nil)).to eq 'unknown' }
  end

  describe '#to_anchor' do
    it { expect( described_class.to_anchor('http://anchor.com')).to eq "<a href=http://anchor.com>http://anchor.com</a>" }
  end

  describe '#to_anchor?' do
    it { expect( described_class.to_anchor?('http://anchor.com')).to eq true }
    it { expect( described_class.to_anchor?('anchor.com')).to eq false }
    it { expect( described_class.to_anchor?('')).to eq false }
    it { expect( described_class.to_anchor?(nil)).to eq false }
    it { expect( described_class.to_anchor?(['http://anchor.com'])).to eq false }
    it { expect( described_class.to_anchor?({a: 'http://anchor.com'})).to eq false }
  end

end
