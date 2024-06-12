require 'rails_helper'

describe 'issue form', js: true do
  before do
    login_to_project_as_user
    visit new_project_issue_path(current_project)
  end

  let(:submit_form) { click_button 'Create Issue' }

  describe 'clicking the \'help\' button' do
    before { find('form .btn-help').click }

    it 'displays Textile help' do
      expect(page).to have_selector '.textile-help'
    end
  end

  describe 'an editor that remembers what view you like' do
    it 'will load source view after using source view' do
      click_link 'Source'

      page.refresh

      expect(page).to have_css('textarea.textile')
    end

    it 'will load fields view after viewing source view but clicking back to fields view' do
      click_link 'Source'
      click_link 'Fields'

      page.refresh

      expect(page).to have_css('.textile-form')
    end
  end

  describe 'a textile form view' do
    before { click_link 'Fields' }

    it 'add fields in the form' do
      current_field_count = all('.textile-form-field').count

      within '.textile-form' do
        click_link 'Add field'
      end

      expect(page).to have_css('.textile-form-field', count: current_field_count + 1)
    end

    it 'remove fields in the form' do
      expect {
        find('[data-behavior=textile-form-field]', match: :first).hover
        within '[data-behavior~=textile-form-field]', match: :first do
          click_link 'Delete'
        end
      }.to change { all('.textile-form-field').count }.by(-1)
    end

    it 'saves the item when submitted' do
      fill_in('item_form[field_name_0]', with: 'Title')
      fill_in('item_form[field_value_0]', with: 'Test Item')

      # Wait for ajax
      within '.textile-preview' do
        find('h5')
        find('p')
      end

      within '.form-actions' do
        find('[type="submit"]').click
      end

      issue = Issue.last

      expect(page).to have_current_path(project_issue_path(current_project, issue), ignore_query: true)
      expect(issue.content).to include("#[Title]#\r\nTest Item")
    end

    it 'supports text without field headers' do
      fieldless_string = "Line 1\nLine 2\n\nLine 4"
      field_string = "#[Field]#\nTest Value"

      click_link 'Source'
      fill_in 'issue_text', with: fieldless_string + "\n" + field_string

      click_link 'Fields'

      expect(find('#item_form_field_name_0').value).to eq ('')
      expect(find('#item_form_field_value_0').value).to eq (fieldless_string)
      expect(find('#item_form_field_name_1').value).to eq ('Field')
      expect(find('#item_form_field_value_1').value).to eq ('Test Value')
    end

    it 'supports fields with duplicated field names' do
      text = "#[Field]#\nValue 1\n\n#[Field]#\nValue 2"

      click_link 'Source'
      fill_in 'issue_text', with: text

      click_link 'Fields'

      expect(find('#item_form_field_name_0').value).to eq ('Field')
      expect(find('#item_form_field_value_0').value).to eq ('Value 1')
      expect(find('#item_form_field_name_1').value).to eq ('Field')
      expect(find('#item_form_field_value_1').value).to eq ('Value 2')
    end
  end
end
