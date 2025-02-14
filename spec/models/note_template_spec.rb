require 'rails_helper'

# Remember NoteTemplate inherits from FileBackedModel which is ActiveModel
# compliant
describe NoteTemplate do
  subject { ::NoteTemplate.new }
  it_behaves_like 'ActiveModel'

  before(:each) do
    allow(NoteTemplate).to receive(:pwd) { Pathname.new('tmp/templates/notes') }
  end
  after(:all) do
    FileUtils.rm_rf('tmp/templates/')
  end

  it 'defines a class .pwd() method' do
    expect(NoteTemplate::methods).to include(:pwd)
    expect(NoteTemplate.pwd).to respond_to('join')
  end

  it 'provides a find(id) method' do
    expect(NoteTemplate::methods).to include(:find)

    # Handle non-existing
    expect { NoteTemplate.find('none_existent') }.to raise_error(FileBackedModel::FileNotFoundException)

    # Handle existing templates
    FileUtils.mkdir_p(NoteTemplate.pwd) unless File.exist?(NoteTemplate.pwd)
    test_file = NoteTemplate.pwd.join('foo.txt')
    File.open(test_file, 'w') { |f| f << 'bar' }
    expect { NoteTemplate.find('foo') }.to_not raise_error()
    nt = NoteTemplate.find('foo')
    expect(nt.content).to eq('bar')
    File.delete(test_file)
  end

  it 'validates presence of filename' do
    nt = NoteTemplate.new(content: 'foobar')
    expect(nt).not_to be_valid()

    nt.filename = 'tpl_test'
    expect(nt).to be_valid()

    nt.filename = nil
    expect(nt).to_not be_valid()

    nt.name = 'My template'
    expect(nt).to be_valid()
  end

  it "doesn't accept bad characters in the name" do
    nt = NoteTemplate.new(name: '../../../../../etc')
    expect(nt).to_not be_valid()

    nt.name = 'foo'
    expect(nt).to be_valid()

    nt.name = 'bar.txt'
    expect(nt).to_not be_valid()
  end

  it 'needs to be valid before it is saved on disk' do
    nt = NoteTemplate.new
    expect(nt).to_not be_valid()
    expect(nt.save).to be false
  end

  pending 'prevents a template from being overwritten'

  it "creates the templates dir if it doesn't exist when saving" do
    FileUtils.rm_rf(NoteTemplate.pwd) if File.exist?(NoteTemplate.pwd)

    nt = NoteTemplate.new(name: 'New Spec Template', content: 'Simple note content: *kapow*!')
    expect(nt.save).to be true

    new_note_template = NoteTemplate.pwd.join('new_spec_template.txt')
    expect(File.exist?(NoteTemplate.pwd)).to be true
    expect(File.exist?(new_note_template)).to be true
    expect(File.read(new_note_template)).to eq('Simple note content: *kapow*!')
    File.delete(new_note_template)
  end

  it 'saves the template contents when saving the instance' do
    nt = NoteTemplate.new(content: 'FooBar', filename: 'tpl_test')
    expect(nt.save).to be true
    filename = NoteTemplate.pwd.join('tpl_test.txt')

    expect(File.exist?(filename)).to be true
    expect(File.read(filename)).to eq('FooBar')
    File.delete(filename)
  end

  it 'deletes file from disk on destroy' do
    nt = NoteTemplate.new(content: 'FooBar', filename: 'tpl_test')
    nt.save

    filename = NoteTemplate.pwd.join('tpl_test.txt')
    expect(File.exist?(filename)).to be true
    expect(nt).to respond_to('destroy')
    expect(nt).to respond_to('delete')
    nt.destroy
    expect(File.exist?(filename)).to be false
  end

  it "destroy() works even if the file doesn't exist any more or never existed" do
    nt = NoteTemplate.new(filename: 'foobar')
    expect { nt.destroy }.not_to raise_error

    FileUtils.mkdir_p(NoteTemplate.pwd) unless File.exist?(NoteTemplate.pwd)
    filename = NoteTemplate.pwd.join('foobar.txt')
    File.open(filename, 'w') { |f| f << 'barfoo' }

    nt = NoteTemplate.from_file(filename)
    expect(nt.content).to eq('barfoo')
    File.delete(filename)

    expect { nt.destroy }.not_to raise_error
  end
end
