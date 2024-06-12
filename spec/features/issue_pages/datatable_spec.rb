require 'rails_helper'

describe 'issue table', js: true do
  subject { page }

  let(:issue) { issues[0] }
  let(:issues) do
    [
      create(
        :issue,
        text: "#[Title]#\nIssue1\n\n#[Risk]#\nHigh\n\n#[Description]#\nn/a",
        node: current_project.issue_library
      ),
      create(:issue, node: current_project.issue_library)
    ]
  end

  let(:tags) do
    Tag::DEFAULT_TAGS.map do |tag|
      create(:tag, name: tag, project: current_project)
    end
  end

  before do
    login_to_project_as_user
    issues
    tags
    visit project_issues_path(current_project)
  end

  describe 'column visibility' do
    let(:default_columns) { ['Title', 'Tags'] }
    let(:hidden_columns) { ['Description', 'Risk'] }

    it 'displays default columns on load' do
      within '.dataTables_wrapper thead tr' do
        default_columns.each do |column|
          expect(page).to have_text(column)
        end
      end
    end

    it 'does not show hidden columns on load' do
      within '.dataTables_wrapper thead tr' do
        hidden_columns.each do |column|
          expect(page).to_not have_text(column)
        end
      end
    end

    it 'can toggle column visibility by clicking on colvis button' do
      within '.dt-buttons.btn-group' do
        page.find('.buttons-colvis').click

        within '.dt-button-collection' do
          click_link hidden_columns[0]
        end
      end

      within '.dataTables_wrapper thead tr' do
        expect(page).to have_text(hidden_columns[0])
      end
    end
  end

  describe 'delete button' do
    it 'is hidden by default' do
      within '.dt-buttons.btn-group' do
        expect(page).to_not have_button('Delete')
      end
    end

    it 'is visible when row checkbox is selected' do
      within '.dataTables_wrapper' do
        page.find('td.select-checkbox', match: :first).click
        expect(page).to have_button('Delete')
      end
    end

    it 'is hidden again after a row checkbox is unselected' do
      within '.dataTables_wrapper' do
        page.find('td.select-checkbox', match: :first).click
        page.find('td.select-checkbox', match: :first).click

        expect(page).to_not have_button('Delete')
      end
    end

    it 'can delete a selected item' do
      within '.dataTables_wrapper' do
        original_row_count = page.all('tbody tr').count
        page.find('td.select-checkbox', match: :first).click

        page.accept_confirm do
          click_button('Delete')
        end

        # Wait for ajax
        page.find('.alert')

        expect(page.all('tbody tr').count).to eq(original_row_count - 1)
        expect(page).to have_text(/deleted/)
      end
    end
  end

  describe 'tagging' do
    it 'shows the tag button when an item is selected' do
      within '.dataTables_wrapper' do
        page.find('td.select-checkbox', match: :first).click
        expect(page).to have_button('Tag')
      end
    end

    it 'shows the available tags' do
      page.find('td.select-checkbox', match: :first).click

      within '.dt-buttons.btn-group' do
        click_button('Tag')

        within '.dt-button-collection' do
          tags.each do |tag|
            expect(page).to have_link(tag.display_name)
          end
        end
      end
    end

    it 'tags the selected issue' do
      page.find('td.select-checkbox', match: :first).click

      within '.dt-buttons.btn-group' do
        click_button('Tag')

        within '.dt-button-collection' do
          click_link(tags.first.display_name)
        end
      end

      # Wait for the spinner to disappear
      expect(page).to_not have_css('[data-behavior=spinner]')
      expect(issue.reload.tags).to include(tags.first)
    end
  end

  describe 'dynamic columns' do
    let(:default_columns) { ['Title', 'Tags'] }

    let(:hide_default_columns) do
      within '.dt-buttons.btn-group' do
        page.find('.buttons-colvis').click

        within '.dt-button-collection' do
          default_columns.each do |column|
            click_link column
          end
        end
      end
    end

    context 'when new fields are added' do
      it 'persists column state' do
        hide_default_columns
        issue.update_attribute(:text, "#[Title]#\nNew Title\n\n#[Risk]#\nHigh\n\n#[Description]#\nn/a\n\n#[New Field]#\nNew Field Value")

        page.refresh

        within '.dataTables_wrapper thead tr' do
          expect(page).to_not have_text('Created')
          expect(page).to_not have_text('Updated')
          expect(page).to_not have_text('New Field')
        end
      end
    end

    context 'when fields are removed' do
      it 'persists column state' do
        hide_default_columns
        issue.update_attribute(:text, "#[Title]#\nIssue1")

        page.refresh

        within '.dataTables_wrapper thead tr' do
          expect(page).to_not have_text('Created')
          expect(page).to_not have_text('Updated')
          expect(page).to_not have_text('New Field')
        end
      end
    end
  end

  it 'can filter rows' do
    within '.dataTables_filter' do
      search_input = page.find('input[type=search]')
      search_input.set(issue.title)
    end

    within '.dataTable' do
      expect(all('tbody tr').count).to eq(1)
    end
  end
end
