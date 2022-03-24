# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.json_helper_debug_verbose ).to eq debug_verbose }
  end

  describe '#key_values_to_table' do
    let(:arr_empty)        { { key: [] } }
    let(:arr_empty_json)   { JSON.dump(arr_empty) }
    let(:arr_empty_table)  { "<table>\n<tr><td>key</td><td>&nbsp;</td></tr>\n</table>\n" }
    let(:arr_1_str)        { { key: [ 'value' ] } }
    let(:arr_1_str_json)   { JSON.dump(arr_1_str) }
    let(:arr_1_str_table)  { "<table>\n<tr><td>key</td><td><table>\n<tr><td>value</td></tr>\n</table>\n</td></tr>\n</table>\n" }
    let(:arr_2_str)        { { key: [ 'v1', 'v2' ] } }
    let(:arr_2_str_json)   { JSON.dump(arr_2_str) }
    let(:arr_2_str_table)  { "<table>\n<tr><td>key</td><td><table>\n<tr><td>v1</td></tr>\n<tr><td>v2</td></tr>\n</table>\n</td></tr>\n</table>\n" }
    let(:hash_empty)       { {} }
    let(:hash_empty_json)  { JSON.dump(hash_empty ) }
    let(:hash_empty_table) { "<table>\n</table>\n" }
    let(:hash_1_str)       { { key: 'value' } }
    let(:hash_1_str_json)  { JSON.dump(hash_1_str ) }
    let(:hash_1_str_table) { "<table>\n<tr><td>key</td><td>value</td></tr>\n</table>\n" }
    let(:hash_2_str)       { { k1: 'v1', k2: 'v2' } }
    let(:hash_2_str_json)  { JSON.dump(hash_2_str) }
    let(:hash_2_str_table) { "<table>\n<tr><td>k1</td><td>v1</td></tr>\n<tr><td>k2</td><td>v2</td></tr>\n</table>\n" }

    context 'hash: empty' do
      it { expect(JsonHelper.key_values_to_table(hash_empty_json, parse: true)).to eq hash_empty_table }
    end
    context 'hash: single key/value string' do
      it { expect(JsonHelper.key_values_to_table(hash_1_str_json, parse: true)).to eq hash_1_str_table }
    end
    context 'hash: two key/value strings' do
      it { expect(JsonHelper.key_values_to_table(hash_2_str_json, parse: true)).to eq hash_2_str_table }
    end
    context 'hash: hash: empty' do
      let(:hash)  { { key: hash_empty } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>#{hash_empty_table}</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
    context 'hash: hash: single key/value string' do
      let(:hash)  { { key: hash_1_str } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>#{hash_1_str_table}</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(json, parse: true)).to eq table }
    end
    context 'hash: hash: arr: single value' do
      let(:hash)  { { key: { k1: arr_1_str } } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td><table>\n<tr><td>k1</td><td><table>\n<tr><td>key</td><td><table>\n<tr><td>value</td></tr>\n</table>\n</td></tr>\n</table>\n</td></tr>\n</table>\n</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(json, parse: true)).to eq table }
    end
    context 'array: empty' do
      it { expect(JsonHelper.key_values_to_table(arr_empty_json, parse: true)).to eq arr_empty_table }
    end
    context 'array: single key/value' do
      it { expect(JsonHelper.key_values_to_table(arr_1_str_json, parse: true)).to eq arr_1_str_table }
    end
    context 'array: two key/value strings' do
      it { expect(JsonHelper.key_values_to_table(arr_2_str_json, parse: true)).to eq arr_2_str_table }
    end
    context 'value: string' do
      let(:hash)  { { key: 'value is a string'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>value is a string</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
    context 'value: string with html elements' do
      let(:hash)  { { key: 'value is a <string>'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>value is a &lt;string&gt;</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
    context 'value: multiple line string' do
      let(:hash)  { { key: 'line1\nline2\nline3'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>line1<br/>line2<br/>line3</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
    context 'value: multiple line string with html elements' do
      let(:hash)  { { key: 'line1\n<line2>\nline3'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>key</td><td>line1<br/>&lt;line2&gt;<br/>line3</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
    context 'value: multiple key value pairs' do
      let(:hash)  { { k1: 'v1', k2: 'v2', k3: 'v3' } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { "<table>\n<tr><td>k1</td><td>v1</td></tr>\n<tr><td>k2</td><td>v2</td></tr>\n<tr><td>k3</td><td>v3</td></tr>\n</table>\n" }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end
  end

  describe '#split_str_into_lines' do
    it { expect(JsonHelper.split_str_into_lines('')).to eq [] }
    it { expect(JsonHelper.split_str_into_lines('str1')).to eq ['str1'] }
    it { expect(JsonHelper.split_str_into_lines("str1\n")).to eq ["str1\n"] } # this is a quirk of the algorithm
    it { expect(JsonHelper.split_str_into_lines("\nstr1")).to eq ["", "str1"] }
    it { expect(JsonHelper.split_str_into_lines("str1\nstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("str1\n\nstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("str1\n\rstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("\\n\n\\n")).to eq ["\\n", "\\n"] }
    it { expect(JsonHelper.split_str_into_lines("str1\\n")).to eq ["str1"] }
    it { expect(JsonHelper.split_str_into_lines("\\nstr1")).to eq ["", "str1"] }
    it { expect(JsonHelper.split_str_into_lines("str1\\nstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("str1\\n\\nstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("str1\\n\\rstr2")).to eq ["str1", "str2"] }
    it { expect(JsonHelper.split_str_into_lines("\\n\\n\\n")).to eq [] }
    it { expect(JsonHelper.split_str_into_lines("\\n\\r\\n")).to eq [] }
  end

end
