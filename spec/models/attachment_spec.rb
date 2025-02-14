require 'rails_helper'

describe Attachment do
  let(:attachment) do
    attachment = Attachment.new(Rails.root.join('public', 'images', 'rails.png'), node_id: node.id)
    attachment.save
    attachment
  end

  let(:node) { create(:node) }

  before do
    attachment
  end

  after do
    FileUtils.rm_rf(Attachment.pwd.join(node.id.to_s))
  end

  it 'should copy the source file into the attachments folder' do
    expect(File.exist?(Attachment.pwd + "#{node.id}/#{attachment.filename}")).to be true
  end

  it 'should be able to find attachments by filename'
  it 'should be able to find all attachments for a given node'
  it 'should recognise Ruby file IO and in particular the <<() method'
  it 'should be re-nameble'

  describe '.find_by' do
    context 'if attachment exists in the file system' do
      it 'returns the attachment object' do
        expect(Attachment.find_by(filename: attachment.filename, node_id: node.id)).to be_a(Attachment)
      end
    end

    context 'if attachment does not exist in the file system' do
      it 'returns nil' do
        expect(Attachment.find_by(filename: 'invalid_attachment.png', node_id: node.id)).to be(nil)
      end
    end
  end

  describe '.fullpath' do
    it 'returns the full file system path to the attachment' do
      expect { attachment.fullpath }.not_to raise_error
      expect(attachment.fullpath.to_s).to eq(File.join(Attachment.pwd, node.id.to_s, attachment.filename))
    end
  end

  describe '.copy_to' do
    after do
      FileUtils.rm_rf(Dir.glob(Attachment.pwd + '*'))
    end

    let(:source_node) { create(:node) }
    let(:target_node) { create(:node) }

    it 'copies itself to a target node' do
      attachment = create(:attachment, node: source_node)
      attachment.copy_to(target_node)

      target_attachment = target_node.attachments.first
      expect(
        FileUtils.compare_file(attachment.fullpath, target_attachment.fullpath)
      ).to be true
    end

    it 'increases the number of attachments on the target node' do
      attachment = create(:attachment, node: source_node)
      attachment.copy_to(target_node)

      expect { attachment.copy_to(target_node) }.to change { target_node.attachments.count }
    end

    it 'renames files if the name is already taken' do
      attachment = create(:attachment, node: source_node)
      attachment.copy_to(source_node)

      # Expect the format filename_copy-01.png
      expected_name = attachment.filename.split('.').insert(1, '_copy-01.').join
      expect(source_node.attachments.any? { |a| a.filename == expected_name }).to eq true
    end
  end
end
