require 'rails_helper'

describe List do
  it { should belong_to(:board).touch(true) }
  it { should belong_to(:previous_list).with_foreign_key(:previous_id) }
  it { should have_many(:cards).dependent(:destroy) }

  it { should validate_presence_of(:board) }
  it { should validate_presence_of(:name) }

  it { should validate_length_of(:name).is_at_most(DB_MAX_STRING_LENGTH) }

  describe 'acts as linked list' do
    let(:model) { List }
    let(:list_item) { 'card' }

    it_behaves_like 'a linked list model'
  end

  before do
    @parent = create(:board)
    @list_item = create(:list, board_id: @parent.id)
  end

  describe 'moving a List around the Board' do
    include_examples 'moving the item'
  end

  describe 'deleting a List' do
    before do
      @list_item2 = create(:list, board_id: @parent.id, previous_id: @list_item.id)
      @activities = create_list(:activity, 2, trackable: @list_item)
      @list_item.destroy
    end

    it 'adjusts the link' do
      expect(@list_item2.reload.previous_id).to be_nil
    end

    it "doesn't delete or nullify any associated Activities" do
      # We want to keep records of actions performed on a evidence even after it's
      # been deleted.
      @activities.each do |activity|
        activity.reload
        expect(activity.trackable).to be_nil
        expect(activity.trackable_id).to eq @list_item.id
        expect(activity.trackable_type).to eq 'List'
      end
    end
  end
end
