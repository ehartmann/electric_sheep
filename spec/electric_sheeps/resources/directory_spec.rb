require 'spec_helper'

describe ElectricSheeps::Resources::Directory do

  it 'is a file system resource' do
    subject.new.respond_to?(:path).must_equal true
    subject.new.respond_to?(:remote).must_equal true
  end

  it 'indicates its type' do
    subject.new.file?.must_equal false
    subject.new.directory?.must_equal true
  end
end