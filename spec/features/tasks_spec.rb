require 'rails_helper'

describe 'My Tasks' do
  subject { page }

  it 'should require authenticated users' do
    project = create(:project)
    visit project_tasks_path(project)
    expect(current_path).to eq(login_path)
    expect(page).to have_content('Access denied.')
  end

  context 'as authenticated user' do
    before do
      login_to_project_as_user

      board = create(:board, project: current_project, node: current_project.methodology_library)
      list = create(:list, board: board)
      @card = create(:card, list: list)
    end

    describe 'in a project' do
      context 'with assigned tasks' do
        it 'renders the user\'s assigned tasks in a dataTable', js: true do
          @card.assignees = [User.first]
          @card.save

          visit project_tasks_path(current_project)
          expect(page).to have_selector('table.dataTable')
          expect(page).to have_selector('td a', text: @card.name)
        end
      end

      context 'without assigned tasks' do
        it 'renders an empty state' do
          @card.assignees = []
          @card.save

          visit project_tasks_path(current_project)
          expect(page).not_to have_selector('table.dataTable')
          expect(page).not_to have_selector('td a', text: @card.name)

          expect(page).to have_selector('.empty-state')
          expect(page).to have_content("You don't have any tasks yet")
        end
      end
    end
  end
end
