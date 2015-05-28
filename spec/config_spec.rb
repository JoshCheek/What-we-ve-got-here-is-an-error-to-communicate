require 'error_to_communicate/config'

RSpec.describe 'configuration', config: true do
  def capture
    yield
    raise 'NO EXCEPTION WAS RAISED!'
  rescue Exception
    return $!
  end

  let(:config_class) { WhatWeveGotHereIsAnErrorToCommunicate::Config }

  def config_for(attrs)
    defaults = {
      theme:       WhatWeveGotHereIsAnErrorToCommunicate::Theme.new,
      format_with: WhatWeveGotHereIsAnErrorToCommunicate::Format,
    }
    config_class.new defaults.merge(attrs)
  end

  # named blacklists
  let(:allow_all)  { lambda { |e| false } }
  let(:allow_none) { lambda { |e| true } }

  # named heuristics
  let :match_all do
    WhatWeveGotHereIsAnErrorToCommunicate::Heuristics::Exception
  end
  let :match_no_method_error do
    WhatWeveGotHereIsAnErrorToCommunicate::Heuristics::NoMethodError
  end

  describe '.default' do
    it 'is a memoized' do
      expect(config_class.default).to equal config_class.default
    end

    it 'is an instance of a default parser' do
      expect(config_class.default           ).to be_a_kind_of config_class
      expect(config_class.default.heuristics).to equal config_class::DEFAULT_HEURISTICS
      expect(config_class.default.blacklist ).to equal config_class::DEFAULT_BLACKLIST
    end
  end

  describe 'accepting an exception' do
    it 'doesn\'t accept non-exception-looking things' do
      config = config_for blacklist:  allow_all, heuristics: [match_all]
      expect(config.accept? nil).to eq false
      expect(config.accept? "omg").to eq false
      expect(config.accept? Struct.new(:message).new('')).to eq false
      expect(config.accept? Struct.new(:backtrace).new([])).to eq false
      expect(config.accept? Struct.new(:message, :backtrace).new('', [])).to eq true
      expect(config.accept? capture { raise }).to eq true
    end

    it 'does not accept anything from its blacklist' do
      config = config_for blacklist: allow_none, heuristics: [match_all]
      expect(config.accept? capture { raise }).to eq false
    end

    it 'accepts anything not blacklisted, that it has a heuristic for' do
      config = config_for blacklist:  allow_all, heuristics: [match_no_method_error]
      expect(config.accept? capture { jjj() }).to eq true
      expect(config.accept? capture { raise }).to eq false
    end
  end

  describe 'finding the heuristic for an exception' do
    it 'raises an ArgumentError if given an acception that it won\'t accept' do
      config = config_for blacklist:  allow_none, heuristics: [match_all]
      expect { config.heuristic_for "not an error" }
        .to raise_error ArgumentError, /"not an error"/
    end

    it 'finds the first heuristic that is willing to accept it' do
      config = config_for blacklist:  allow_all,
                          heuristics: [match_no_method_error, match_all]
      exception = capture { sdfsdfsdf() }
      expect(config.heuristic_for exception).to     be_a_kind_of match_no_method_error
      expect(config.heuristic_for exception).to_not be_a_kind_of match_all
    end
  end

  describe 'The default configuration' do
    let(:default_config) { config_class.new_default }

    describe 'blacklist' do
      it 'doesn\'t accept a SystemExit' do
        system_exit = capture { exit 1 }
        expect(default_config.accept? system_exit).to eq false

        generic_exception = capture { raise }
        expect(default_config.accept? generic_exception).to eq true
      end
    end

    describe 'heuristics (these are unit-tested in spec/heuristics, and correct selection is tested in spec/acceptance)' do
      it 'has heuristics for WrongNumberOfArguments' do
        expect(default_config.heuristics).to include \
          WhatWeveGotHereIsAnErrorToCommunicate::Heuristics::WrongNumberOfArguments
      end

      it 'has heuristics for NoMethodError' do
        expect(default_config.heuristics).to include \
          WhatWeveGotHereIsAnErrorToCommunicate::Heuristics::NoMethodError
      end

      it 'has heuristics for Exception' do
        expect(default_config.heuristics).to include \
          WhatWeveGotHereIsAnErrorToCommunicate::Heuristics::Exception
      end
    end
  end
end
