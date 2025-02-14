require 'rails_helper'

# This runs ActiveModel::Lint tests
# See:
#   https://gist.github.com/1892874
describe FileBackedModel do

  class BasicFileBackedModel
    include FileBackedModel
    set_pwd Rails.root.join('tmp/templates/bfbm').to_s
  end

  subject { ::BasicFileBackedModel.new }
  let(:pwd) { BasicFileBackedModel.pwd }
  let(:rspec_file) { pwd.join('rspec.txt') }
  it_behaves_like 'ActiveModel'

  after(:all) do
    FileUtils.rm_rf('tmp/templates/')
    ::Configuration::where(name: 'admin:paths:rspec').limit(1).destroy_all
  end

  # ------------------------------------------------------- Class configuration
  describe '.extension' do
    it 'defaults to a .txt extension' do
      expect(BasicFileBackedModel.extension).to eq('.txt')
    end
    it 'allows including classes to define their own' do
      class ExtensionFBM
        include FileBackedModel
        set_extension :xml
      end

      expect(ExtensionFBM.extension).to eq('.xml')
    end
  end

  # ----------------------------------------------------------- File operations
  describe '.from_file' do
    it 'loads an instance based on the file on disk' do
      FileUtils.mkdir_p(pwd) unless File.exist?(pwd)
      File.open(rspec_file, 'w') { |f| f << 'bar' }

      expect(subject.class).to respond_to(:from_file)
      # expect(subject.class.from_file).to raise_error

      instance = subject.class.from_file(rspec_file)
      expect(instance).to be_a(subject.class)
      expect(instance.filename).to eq('rspec')
      expect(instance.content).to eq('bar')

      FileUtils.rm(rspec_file)
    end
  end

  describe '#destroy' do
    it "returns true if the file hasn't been saved to disk yet" do
      instance = BasicFileBackedModel.new
      expect(instance.destroy).to be true
    end

    it 'deletes the file from disk if this is a file-backed model' do
      FileUtils.mkdir_p(pwd) unless File.exist?(pwd)
      File.open(rspec_file, 'w') { |f| f << 'foobar' }

      expect(File.exist?(rspec_file)).to be true
      instance = subject.class.from_file(rspec_file)
      expect(instance.destroy).to eq(instance)
      expect(File.exist?(rspec_file)).to be false
    end
  end

  describe '#save' do
    pending 'generates a filename using the #name if provided' do
      subject.name = 'Singing in the rain'
      should be true

      full_path = pwd.join('singing_in_the_rain.txt')
      expect(File.exist?(full_path)).to be true

      expect(subject.filename).to eq('singing_in_the_rain')

      FileUtils.rm(full_path)
    end

    # Note that the model :validates_presence_of :name, so this won't happen
    # it "auto-generates a filename if no #name was provided" do
    # end

    it 'overwrites the contents of the file on disk' do
      subject.name = 'rspec name'
      subject.content = 'barfoo'
      expect(subject.save).to be true
      expect(File.exist?(subject.full_path)).to be true
      expect(File.read(subject.full_path)).to eq('barfoo')

      FileUtils.rm(subject.full_path)
    end
  end

  # ------------------------------------------------------------------- Finders
  describe '.all' do
    it 'returns a new instance for each file in the .pwd' do
      FileUtils.mkdir_p(pwd) unless File.exist?(pwd)

      (1..3).each do |i|
        File.open(pwd.join("#{i}.txt"), 'w') { |f| f << 'foo' }
      end

      expect(BasicFileBackedModel.all.count).to eq(3)
    end
  end

  describe '.find(:id)' do
    it "raises an exception when the :id isn't found in the .pwd" do
      expect(subject.class).to respond_to(:find)
      expect do
        subject.class.find('badfile')
      end.to raise_exception(FileBackedModel::FileNotFoundException)
    end

    it 'loads an instance based on the file name' do
      FileUtils.mkdir_p(pwd) unless File.exist?(pwd)
      File.open(rspec_file, 'w') { |f| f << 'bar' }

      expect(subject.class).to respond_to(:find)

      instance = subject.class.find('rspec')

      expect(instance).to be_a(subject.class)
      expect(instance.filename).to eq('rspec')
      expect(instance.content).to eq('bar')

      FileUtils.rm(rspec_file)
    end
  end

  # ---------------------------------------------------------- Instance methods
  describe '#name' do
    it 'responds to #name based on the filename' do
      FileUtils.mkdir_p(pwd) unless File.exist?(pwd)
      File.open(rspec_file, 'w') { |f| f << 'bar' }

      bfbm = BasicFileBackedModel.from_file(rspec_file)
      expect(bfbm).to respond_to(:name)
      expect(bfbm.name).to eq('Rspec')

      FileUtils.rm(rspec_file)
    end

    it "doesn't accept names with invalid characters" do
      subject.name = 'valid name'
      should be_valid()
      subject.name = 'foo/../bar.txt'
      should_not be_valid()
      expect(subject.errors[:name]).to_not be_empty
    end
  end
end
