require 'rails_helper'

describe Board do
  it { should belong_to(:node) }
  it { should have_many(:lists).dependent(:destroy) }
  it { should have_many(:cards).through(:lists) }

  it { should validate_presence_of(:name) }

  it { should validate_length_of(:name).is_at_most(DB_MAX_STRING_LENGTH) }

  describe 'acts as linked list' do
    let(:model) { Board }
    let(:list_item) { 'list' }

    it_behaves_like 'a linked list model'
  end

  describe '#create' do
    before do
      @node = create(:node)
      create(:board, node: @node)
    end

    it 'validates that the node does not have already a board' do
      board = build(:board, node: @node)

      expect(board.save).to be false
      expect(board.errors.messages[:node]).to include 'already has a board'
    end
  end

  describe '#delete' do
    before do
      @board = create(:board)
      @activities = create_list(:activity, 2, trackable: @board)
      @board.destroy
    end

    it "doesn't delete or nullify any associated Activities" do
      # We want to keep records of actions performed on a evidence even after it's
      # been deleted.
      @activities.each do |activity|
        activity.reload
        expect(activity.trackable).to be_nil
        expect(activity.trackable_id).to eq @board.id
        expect(activity.trackable_type).to eq 'Board'
      end
    end
  end
end
