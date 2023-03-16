# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.json_helper_debug_verbose ).to eq debug_verbose }
  end

  describe '#key_values_to_table' do
    let(:css_table0)         { JsonHelper.css_table( add: true, depth: 0 ) }
    let(:css_table1)         { JsonHelper.css_table( add: true, depth: 1 ) }
    let(:css_table2)         { JsonHelper.css_table( add: true, depth: 2 ) }
    let(:css_table3)         { JsonHelper.css_table( add: true, depth: 3 ) }
    let(:css_td_key0)        { JsonHelper.css_td_key( add: true, depth: 0 ) }
    let(:css_td_key1)        { JsonHelper.css_td_key( add: true, depth: 1 ) }
    let(:css_td_key2)        { JsonHelper.css_td_key( add: true, depth: 2 ) }
    let(:css_td_key3)        { JsonHelper.css_td_key( add: true, depth: 3 ) }
    let(:css_td0)            { JsonHelper.css_td( add: true, depth: 0 ) }
    let(:css_td1)            { JsonHelper.css_td( add: true, depth: 1 ) }
    let(:css_td2)            { JsonHelper.css_td( add: true, depth: 2 ) }
    let(:css_td3)            { JsonHelper.css_td( add: true, depth: 3 ) }
    let(:css_tr0)            { JsonHelper.css_tr( add: true, depth: 0 ) }
    let(:css_tr1)            { JsonHelper.css_tr( add: true, depth: 1 ) }
    let(:css_tr2)            { JsonHelper.css_tr( add: true, depth: 2 ) }
    let(:css_tr3)            { JsonHelper.css_tr( add: true, depth: 3 ) }
    let(:arr_empty)          { { key: [] } }
    let(:arr_empty_json)     { JSON.dump(arr_empty) }
    let(:arr_empty_table)    { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>&nbsp;</td></tr>
</table>
end_of_value
      value
    }
    let(:arr_1_str)          { { key: [ 'value' ] } }
    let(:arr_1_str_json)     { JSON.dump(arr_1_str) }
    let(:arr_1_str_table)    { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}><table#{css_table1}>
<tr#{css_tr1}><td#{css_td_key1}>value</td></tr>
</table>
</td></tr>
</table>
end_of_value
      value
    }
    let(:arr_2_str)          { { key: [ 'v1', 'v2' ] } }
    let(:arr_2_str_json)     { JSON.dump(arr_2_str) }
    let(:arr_2_str_table)    { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}><table#{css_table1}>
<tr#{css_tr1}><td#{css_td_key1}>v1</td></tr>
<tr#{css_tr1}><td#{css_td1}>v2</td></tr>
</table>
</td></tr>
</table>
end_of_value
      value
    }
    let(:hash_empty)         { {} }
    let(:hash_empty_json)    { JSON.dump(hash_empty ) }
    let(:hash_empty_table0)  { "<table#{css_table0}>\n</table>\n" }
    let(:hash_empty_table1)  { "<table#{css_table1}>\n</table>\n" }
    let(:hash_1_str)         { { key: 'value' } }
    let(:hash_1_str_json)    { JSON.dump(hash_1_str) }
    let(:hash_1_str_table0)  { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>value</td></tr>
</table>
end_of_value
      value
    }
    let(:hash_1_str_table1)  { value=<<-end_of_value
<table#{css_table1}>
<tr#{css_tr1}><td#{css_td_key1}>key</td><td#{css_td1}>value</td></tr>
</table>
end_of_value
      value
    }
    let(:hash_2_str)        { { k1: 'v1', k2: 'v2' } }
    let(:hash_2_str_json)   { JSON.dump(hash_2_str) }
    let(:hash_2_str_table0) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>k1</td><td#{css_td0}>v1</td></tr>
<tr#{css_tr0}><td#{css_td_key0}>k2</td><td#{css_td0}>v2</td></tr>
</table>
end_of_value
      value
    }

    context 'hash: empty' do
      it { expect(JsonHelper.key_values_to_table(hash_empty_json, parse: true)).to eq hash_empty_table0 }
    end

    context 'hash: single key/value string' do
      it { expect(JsonHelper.key_values_to_table(hash_1_str_json, parse: true)).to eq hash_1_str_table0 }
    end

    context 'hash: two key/value strings' do
      it { expect(JsonHelper.key_values_to_table(hash_2_str_json, parse: true)).to eq hash_2_str_table0 }
    end

    context 'hash: hash: empty' do
      let(:hash)  { { key: hash_empty } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>#{hash_empty_table1}</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end

    context 'hash: hash: single key/value string' do
      let(:hash)  { { key: hash_1_str } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>#{hash_1_str_table1}</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(json, parse: true)).to eq table }
    end

    context 'hash: hash: arr: single value' do
      let(:hash)  { { key: { k1: arr_1_str } } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}><table#{css_table1}>
<tr#{css_tr1}><td#{css_td_key1}>k1</td><td#{css_td1}><table#{css_table2}>
<tr#{css_tr2}><td#{css_td_key2}>key</td><td#{css_td2}><table#{css_table3}>
<tr#{css_tr3}><td#{css_td_key3}>value</td></tr>
</table>
</td></tr>
</table>
</td></tr>
</table>
</td></tr>
</table>
end_of_value
        value
      }
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
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>value is a string</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end

    context 'value: string with html elements' do
      let(:hash)  { { key: 'value is a <string>'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>value is a &lt;string&gt;</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end

    context 'value: multiple line string' do
      let(:hash)  { { key: 'line1\nline2\nline3'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>line1<br/>line2<br/>line3</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end

    context 'value: multiple line string with html elements' do
      let(:hash)  { { key: 'line1\n<line2>\nline3'} }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>key</td><td#{css_td0}>line1<br/>&lt;line2&gt;<br/>line3</td></tr>
</table>
end_of_value
        value
      }
      it { expect(JsonHelper.key_values_to_table(hash, parse: true)).to eq table }
    end

    context 'value: multiple key value pairs' do
      let(:hash)  { { k1: 'v1', k2: 'v2', k3: 'v3' } }
      let(:json)  { JSON.dump(hash) }
      let(:table) { value=<<-end_of_value
<table#{css_table0}>
<tr#{css_tr0}><td#{css_td_key0}>k1</td><td#{css_td0}>v1</td></tr>
<tr#{css_tr0}><td#{css_td_key0}>k2</td><td#{css_td0}>v2</td></tr>
<tr#{css_tr0}><td#{css_td_key0}>k3</td><td#{css_td0}>v3</td></tr>
</table>
end_of_value
        value
      }
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
