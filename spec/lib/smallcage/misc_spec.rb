require 'spec_helper.rb'
require 'smallcage'

describe 'misc' do
  it 'returns empty string' do
    expect(''.camelize).to eq ''
  end

  it 'camelize String' do
    expect('smallcage'.camelize).to eq 'Smallcage'
    expect('abc_def_ghi'.camelize).to eq 'AbcDefGhi'
  end

  it 'camelize with first character in lower case' do
    expect('smallcage'.camelize(false)).to eq 'smallcage'
    expect('abc_def_ghi'.camelize(false)).to eq 'abcDefGhi'
  end
end
