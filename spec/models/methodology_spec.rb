require 'rails_helper'

# This runs ActiveModel::Lint tests
# See:
#   https://gist.github.com/1892874
describe Methodology do
  subject { ::Methodology.new }

  it { should validate_presence_of :content }

  # FIXME, right now ActiveModel lint fails because to_params returns the filename even if
  # persisted? is false.
  # The problem is we're using an spurious Methodology object (whose backend is a Note and
  # not a file on disk, like when we go admin::templates::methodologies) in the
  # MethodologiesController
  # We need to address this by making Methodology a 1st class citizen of
  # the app.
  pending do
    it_behaves_like 'ActiveModel'
  end unless ENV['CI']

  before(:each) do
    allow(Methodology).to receive(:pwd).and_return(Pathname.new('tmp/templates/methodologies'))
  end
  after(:all) do
    FileUtils.rm_rf('tmp/templates')
  end

  describe '#destroy' do
    it 'deletes file from disk on destroy' do
      mt = Methodology.new(
        content: '<foo version="2">bar</foo>',
        filename: 'mt_test'
      )
      mt.save

      filename = Methodology.pwd.join('mt_test.xml')
      expect(File.exist?(filename)).to be true
      expect(mt).to respond_to('destroy')
      expect(mt).to respond_to('delete')
      mt.destroy
      expect(File.exist?(filename)).to be false
    end

    it "destroy() works even if the file doesn't exist any more or never existed" do
      mt = Methodology.new(filename: 'foobar')
      expect { mt.destroy }.not_to raise_error

      filename = Methodology.pwd.join('foobar.xml')
      FileUtils.mkdir_p(Methodology.pwd)
      File.open(filename, 'w') { |f| f << 'barfoo' }

      mt = Methodology.from_file(filename)
      expect(mt.content).to eq('barfoo')
      File.delete(filename)

      expect { mt.destroy }.not_to raise_error
    end
  end

  describe '#name=' do
    it 'updates content when setting :name attribute' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/webapp.xml')
      methodology.name = 'Foo'
      expect(methodology.name).to eq('Foo')
      expect(methodology.content).to include('Foo')
    end
  end

  describe '#save' do
    it "creates the base dir if it doesn't exist when saving" do
      FileUtils.rm_rf(Methodology.pwd) if File.exist?(Methodology.pwd)

      Timecop.freeze(Time.now)

      content = '<board version="2">Simple methodology content: *kapow*!</board>'
      mt = Methodology.new(content: content)
      expect(mt.save).to be true

      new_methodology = Methodology.pwd.join("auto_#{Time.now.to_i}.xml")
      expect(File.exist?(Methodology.pwd)).to be true
      expect(File.exist?(new_methodology)).to be true
      expect(File.read(new_methodology)).to eq(content)
      File.delete(new_methodology)

      Timecop.return
    end

    it 'saves the template contents when saving the instance' do
      mt = Methodology.new(
        content: '<foo version="2">bar</foo>',
        filename: 'mt_test'
      )
      expect(mt.save).to be true
      filename = Methodology.pwd.join('mt_test.xml')
      expect(File.exist?(filename)).to be true
      expect(File.read(filename)).to eq('<foo version="2">bar</foo>')
      File.delete(filename)
    end
  end

  describe '#to_html_anchor' do
    it 'discards non-alphanumeric characters in the name' do
      methodology = Methodology.new(filename: 'mt_test')

      methodology.name = 'Foo [Bar]'
      expect(methodology.to_html_anchor).not_to match(/[^0-9a-z\-\_]/i)

      methodology.name = '(Foo) Bar'
      expect(methodology.to_html_anchor).not_to match(/[^0-9a-z\-\_]/i)

      methodology.name = 'Foo.Bar'
      expect(methodology.to_html_anchor).not_to match(/[^0-9a-z\-\_]/i)
    end
  end

  context 'working with tasks' do
    it 'defines a #tasks method that returns the list of tasks across sections' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/webapp.xml')
      expect(methodology).to respond_to(:tasks)
      expect(methodology.tasks).to respond_to(:count)
      expect(methodology.tasks.count).to eq(4)
    end

    it 'defines a #completed_tasks method that returns the list of tasks already completed' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/webapp.xml')
      expect(methodology).to respond_to(:completed_tasks)
      expect(methodology.completed_tasks).to respond_to(:count)
      expect(methodology.completed_tasks.count).to eq(0)

      # Where is my developer pride? You let me know when you find it. Ugg!
      methodology.doc.at_xpath('//task').set_attribute('checked', 'checked')
      expect(methodology.completed_tasks.count).to eq(1)
    end
  end

  describe '#lists' do
    it 'defines a #lists method that returns the list of tasks across sections' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/v2_template.xml')
      expect(methodology).to respond_to(:lists)
      expect(methodology.lists).to respond_to(:count)
      expect(methodology.lists.count).to eq(2)
      # NOTE: ".lists" is an Array of "List" objects, we can
      # call Array#count on it. But for each lists, the "#cards"
      # method is an unpersisted ActiveRecord Collection, so count
      # will always be 0 (until we call "save" on the list)
      expect(methodology.lists.first.cards.size).to eq(2)
      expect(methodology.lists.last.cards.size).to eq(1)
    end
  end

  describe '#version' do
    it 'returns 1 when not specified and root element is "methodology"' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/webapp.xml')
      expect(methodology.version).to eq(1)
    end

    it 'returns 2 when not specified and root element is "board"' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/v2_template.xml')
      expect(methodology.version).to eq(2)
    end

    it 'returns the version specified when available' do
      methodology = Methodology.from_file('spec/fixtures/files/methodologies/vX_template.xml')
      expect(methodology.version).to eq(96)
    end
  end
end
