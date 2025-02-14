require 'rails_helper'

describe ConflictResolver do
  let(:dummy_class) do
    Class.new do
      include ConflictResolver

      attr_accessor :conflicting_revisions, :params, :session

      def initialize(params, session)
        @params = params
        @session = session
      end

      def testing_method1(record, updated_at_before_save)
        check_for_edit_conflicts(record, updated_at_before_save)
      end

      def testing_method2(record)
        load_conflicting_revisions(record)
      end
    end
  end

  before do
    @original_updated_at = Time.now - 1.day
    params = { 'issue' => { original_updated_at: @original_updated_at } }

    @issue = create(:issue)
    @dummy_instance = dummy_class.new(params, {})
  end

  describe '#check_for_edit_conflicts' do
    it 'save the last conflicting update' do
      @dummy_instance.testing_method1(@issue, Time.now.to_i)

      expect(@dummy_instance.session[:update_conflicts_since]).to eq(Time.at(@original_updated_at.to_i + 1).utc.to_fs(:db))
    end
  end

  describe '#load_conflicting_revisions' do
    it 'returns edit conflicts' do
      PaperTrail.enabled = true

      @issue.update(text: "#[Title]#\nUpdated issue\n\n")
      @dummy_instance.testing_method1(@issue, Time.now.to_i)
      @dummy_instance.testing_method2(@issue)

      revisions = @dummy_instance.conflicting_revisions

      expect(revisions).to eq(@issue.versions)
    end
  end
end
