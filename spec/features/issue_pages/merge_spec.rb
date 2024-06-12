require 'rails_helper'

describe 'issue pages' do
  describe 'merge page', js: true do
    before do
      login_to_project_as_user

      # create 2 issues
      @issue1 = create(:issue, node: current_project.issue_library)
      @issue2 = create(:issue, node: current_project.issue_library)

      visit project_issues_path(current_project)

      # click > 1 issue checkboxes
      page.all('td.select-checkbox').each(&:click)

      # click the merge button
      find('span', text: 'Merge').click
    end

    it 'merges issues into an existing one' do
      expect(page).to have_content /You're merging 2 Issues into a target Issue/i

      click_button 'Merge issues'

      expect(page).to have_content('1 issue merged into ')
    end

    context 'merge issues into a new one', js: true do
      it 'creates a new issue' do
        expect(page).to have_content /You're merging 2 Issues into a target Issue/i

        # new issue form should not be visible yet
        expect(page).to have_selector('#new_issue', visible: false)

        choose('Merge into a new issue')
        click_link 'Source'

        # new issue form should be visible now
        expect(page).to have_selector('#new_issue', visible: true)

        # click button like this because the button may be moving down
        # due to bootstrap accordion unfold transition
        find_button('Merge issues').send_keys(:return) # click_button "Merge issues"

        expect(page).to have_content(/2 issues merged into/i)

        # We start with 2, but merge into a single one
        expect(Issue.count).to eq(1)
        expect(Issue.last.author).to eq(@logged_in_as.email)
      end

      it 'tags the new issue based on the #[Tags]#' do
        expect(page).to have_content /You're merging 2 Issues into a target Issue/i

        # new issue form should not be visible yet
        expect(page).to have_selector('#new_issue', visible: false)

        choose('Merge into a new issue')

        # new issue form should be visible now
        expect(page).to have_selector('#new_issue', visible: true)

        tag_name = '!2ca02c_info'
        click_link 'Source'
        fill_in :issue_text, with: "#[Title]#\nMerged issue\n\n#[Tags]#\n#{tag_name}\n\n"

        # click button like this because the button may be moving down
        # due to bootstrap accordion unfold transition
        find_button('Merge issues').send_keys(:return) # click_button "Merge issues"

        expect(page).to have_content(/2 issues merged into Merged issue/i)
        expect(Issue.last.reload.tag_list).to eq(tag_name)
      end
    end

    let(:submit_form) {
      click_button 'Merge issues'
    }
    include_examples 'deleted item is listed in Trash', :issue
  end
end
