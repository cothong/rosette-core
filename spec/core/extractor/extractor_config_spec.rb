# encoding: UTF-8

require 'spec_helper'

include Rosette::Core

describe ExtractorConfig do
  let(:extractor_class) { Rosette::Extractors::Test::TestExtractor }

  it 'instantiates the extractor given' do
    ExtractorConfig.new(extractor_class).tap do |config|
      expect(config.extractor).to be_instance_of(extractor_class)
    end
  end

  it 'sets a default encoding' do
    ExtractorConfig.new(extractor_class).tap do |config|
      expect(config.encoding).to eq(Rosette::Core::DEFAULT_ENCODING)
    end
  end

  describe '#set_encoding' do
    let(:config) { ExtractorConfig.new(extractor_class) }

    it 'sets the encoding on the instance' do
      config.set_encoding(Encoding::UTF_16BE).tap do |config_with_encoding|
        expect(config_with_encoding).to be(config)
        expect(config_with_encoding.encoding).to eq(Encoding::UTF_16BE)
      end
    end
  end
end

describe ExtractorConfigurationFactory do
  let(:factory) { ExtractorConfigurationFactory }

  describe '#create_root' do
    it 'returns an empty, generic node' do
      # instance_of returns false for subclasses of Node
      expect(factory.create_root).to be_instance_of(factory::Node)
    end
  end

  let(:root) { factory.create_root }

  describe 'operators' do
    it 'supports the and binary operator' do
      node = root.match_path('foo/bar').and(root.match_path('foo/baz'))
      expect(node).to be_a(factory::BinaryNode)
      expect(node).to be_a(factory::AndNode)

      node.left.tap do |left|
        expect(left).to be_a(factory::PathNode)
        expect(left.path).to eq('foo/bar')
      end

      node.right.tap do |right|
        expect(right).to be_a(factory::PathNode)
        expect(right.path).to eq('foo/baz')
      end
    end

    it 'supports the or binary operator' do
      node = root.match_path('foo/bar').or(root.match_path('foo/baz'))
      expect(node).to be_a(factory::BinaryNode)
      expect(node).to be_a(factory::OrNode)

      node.left.tap do |left|
        expect(left).to be_a(factory::PathNode)
        expect(left.path).to eq('foo/bar')
      end

      node.right.tap do |right|
        expect(right).to be_a(factory::PathNode)
        expect(right.path).to eq('foo/baz')
      end
    end

    it 'supports the unary not operator' do
      node = root.match_path('foo/bar').not
      expect(node).to be_a(factory::UnaryNode)
      expect(node).to be_a(factory::NotNode)

      node.child.tap do |child|
        expect(child).to be_a(factory::PathNode)
        expect(child.path).to eq('foo/bar')
      end
    end
  end
end

context 'nodes' do
  let(:factory) { ExtractorConfigurationFactory }
  let(:root) { factory.create_root }

  describe ExtractorConfigurationFactory::AndNode do
    describe '#matches?' do
      it 'returns true if both paths match, false otherwise' do
        node = root.match_path('foo/bar').and(root.match_path('foo/bar/baz'))
        expect(node).to be_a(factory::AndNode)
        expect(node.matches?('foo/bar/baz/goo')).to be_truthy
        expect(node.matches?('foo/bar')).to be_falsy
      end
    end
  end

  describe ExtractorConfigurationFactory::OrNode do
    describe '#matches?' do
      it 'returns true if either path matches, false otherwise' do
        node = root.match_path('foo').or(root.match_path('goo'))
        expect(node).to be_a(factory::OrNode)
        expect(node.matches?('foo')).to be_truthy
        expect(node.matches?('foo/bar')).to be_truthy
        expect(node.matches?('goo')).to be_truthy
        expect(node.matches?('goo/boo')).to be_truthy
        expect(node.matches?('ya/ya')).to be_falsy
      end
    end
  end

  describe ExtractorConfigurationFactory::NotNode do
    describe '#matches?' do
      it "returns true if the path doesn't match, false otherwise" do
        node = root.match_path('foo').not
        expect(node).to be_a(factory::NotNode)
        expect(node.matches?('bar')).to be_truthy
        expect(node.matches?('foo')).to be_falsy
        expect(node.matches?('foo/bar')).to be_falsy
      end
    end
  end

  describe ExtractorConfigurationFactory::FileExtensionNode do
    describe '#matches?' do
      it 'returns true if the file extension matches, false otherwise' do
        node = root.match_file_extension('.rb')
        expect(node).to be_a(factory::FileExtensionNode)
        expect(node.matches?('file.rb')).to be_truthy
        expect(node.matches?('file.txt')).to be_falsy
      end
    end
  end

  describe ExtractorConfigurationFactory::PathNode do
    describe '#matches?' do
      it 'returns true if the path matches, false otherwise' do
        node = root.match_path('foo/bar')
        expect(node).to be_a(factory::PathNode)
        expect(node.matches?('foo/bar')).to be_truthy
        expect(node.matches?('foo/bar/baz')).to be_truthy
        expect(node.matches?('foo')).to be_falsy
      end
    end
  end

  describe ExtractorConfigurationFactory::RegexNode do
    describe '#matches?' do
      it 'returns true if the path matches a regex, false otherwise' do
        node = root.match_regex(/[a-z]{2}\.rb/)
        expect(node).to be_a(factory::RegexNode)
        expect(node.matches?('fi.rb')).to be_truthy
        expect(node.matches?('fi.txt')).to be_falsy
      end
    end
  end
end
