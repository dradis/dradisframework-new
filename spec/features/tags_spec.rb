require 'rails_helper'

describe 'Tag pages:' do
  subject { page }

  before do
    login_to_project_as_user
  end

  describe 'tags#index', js: true do
    let!(:tag) { create(:tag, name: '!9467bd_critical' , project: current_project) }
    before do
      visit project_tags_path(current_project)
    end
    let(:default_columns) { ['Name'] }
    let(:hidden_columns) { ['Color', 'Created', 'Updated'] }
    let(:filter) { { keyword: tag.name, filter_count: 1 } }

    it_behaves_like 'a DataTable'

    describe 'can delete tag', js: true do
      it 'deletes the Tag' do
        page.find("tr#tag-#{tag.id}").hover
        page.accept_confirm do
          click_link('Delete')
        end
        expect(page).to have_text('Tag deleted.')
        expect(Tag.exists?(tag.id)).to be false
      end
    end

    describe 'can edit tag', js: true do
      it 'updates the Tag' do
        page.find("tr#tag-#{tag.id}").hover
        click_link('Edit')
        fill_in :tag_name, with: 'test'
        fill_in :tag_color, with: '#000000'
        expect do
          click_button 'Update Tag'
        end.to change { tag.reload.name }.from('!9467bd_critical').to('!000000_test')
        expect(page).to have_text('Tag updated.')
      end
    end
  end

  describe 'create and manage tags' do
    describe 'issue form', js: true do
      before do
        visit new_project_issue_path(current_project)
        page.find('.dropdown-toggle span.tag').click
      end

      it 'creates a tag' do
        click_link 'Add new tag'
        fill_in :tag_name, with: 'test'
        fill_in :tag_color, with: '#000000'
        expect do
          click_button 'Create Tag'
        end.to change { current_project.tags.count }.by(1)
        expect(page).to have_text('Tag created.')
        page.find('.dropdown-toggle span.tag').click
        expect(page).to have_link('Test')
      end

      it 'renders manage tag' do
        click_link 'Manage tags'
        expect(page).to have_current_path(project_tags_path(current_project))
      end
    end

    describe 'issues index', js: true do
      let!(:issue) { create(:issue, node: current_project.issue_library) }

      before do
        visit project_issues_path(current_project)
        page.find('td.select-checkbox', match: :first).click
        click_button('Tag')
      end

      it 'creates a tag' do
        click_link 'Add new tag'
        fill_in :tag_name, with: 'ultra'
        fill_in :tag_color, with: '#555555'
        expect do
          click_button 'Create Tag'
        end.to change { current_project.tags.count }.by(1)
        expect(page).to have_text('Tag created.')
        page.find('td.select-checkbox', match: :first).click
        click_button('Tag')
        expect(page).to have_link('Ultra')
      end

      it 'renders manage tag' do
        click_link 'Manage Tags'
        expect(current_path).to eq(project_tags_path(current_project))
      end
    end
  end
end
