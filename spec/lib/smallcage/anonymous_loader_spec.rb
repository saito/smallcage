require 'spec_helper'
require 'smallcage'

describe SmallCage::AnonymousLoader do
  let(:root_dir) { File.join(SPEC_DATA_DIR, 'anonymous_loader') }
  let(:dir1) { File.join(root_dir, '1') }

  it 'loads ruby files' do
    result = SmallCage::AnonymousLoader.load(dir1, /(test\d)\.rb\z/)
    expect(result[:names]).to eq %w{Test1 Test2}
    expect(result[:module]::TEST_1).to eq 1
    expect(result[:module]::TEST_2).to eq 2
  end

  context 'when directory does not exist' do
    it 'returns empty result' do
      dir = File.join(root_dir, '0')
      result = SmallCage::AnonymousLoader.load(dir, /(test\d)\.rb\z/)
      expect(result[:names]).to eq []
      expect(result[:module]).to be_a(Module)
    end
  end

  context 'when loaded file cause error' do
    subject { SmallCage::AnonymousLoader.load(dir1, pattern) }

    context '1 / 0' do
      let(:pattern) { /(error1)\.rb\z/ }
      it { expect { subject }.to raise_error ZeroDivisionError }
    end

    context 'require "_no_such_file_"' do
      let(:pattern) { /(error2)\.rb\z/ }
      it { expect { subject }.to raise_error LoadError }
    end
  end
end
