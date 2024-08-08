require 'rails_helper'

describe 'Sessions' do
  subject { page }

  # This matches fixtures/configurations.yml value.
  let(:password) { 'rspec_pass' }
  let(:user) do
    create(
      :user,
      :author,
      password_hash: ::BCrypt::Password.create(password)
    )
  end

  # This needs to be a helper and not a let() block, because let is memoized
  # and reused.
  def login
    # This gets us past Setup: Step 2
    project = create(:project)
    project.issue_library

    visit login_path
    fill_in 'login', with: user.email
    fill_in 'password', with: password
    click_button 'Log in'
  end

  context 'when using the correct password' do
    it 'users can log in' do
      login

      expect(current_path).to eq(project_path(Project.find(1)))
    end
  end

  context 'when using an incorrect password' do
    let(:password) { 'wrong_pass'}

    it 'redirect to login with a message' do
      login

      expect(current_path).to eq(login_path)
      expect(page).to have_content('Invalid credentials')
    end
  end

  context 'when session is expired' do
    it 'redirect to login with a message' do
      login

      travel_to(Time.now + 1.hour)
      visit project_path(Project.find(1))

      expect(current_path).to eq(login_path)
      expect(page).to have_content('Session timed out!')
    end

    describe 'return after timeout' do
      let(:project) { create(:project) }

      let(:submit_login_details) do
        fill_in 'login', with: user.email
        fill_in 'password', with: password
        click_button 'Log in'
      end

      before do
        login
      end

      it 'redirects to previous page' do
        travel_to(Time.now + 1.hour)
        visit new_project_issue_path(project)
        submit_login_details
        expect(current_path).to eq(new_project_issue_path(project))
      end

      context 'when editing in Source view while timed out' do
        it 'shows an alert on the page', js: true do
          visit new_project_issue_path(project)
          click_link 'Source'

          travel_to(Time.now + 1.hour)

          fill_in :issue_text, with: 'some text'
          expect(page).to have_text('Your session has expired!. Login again to continue.')
        end
      end

      context 'when editing in Fields view while timed out' do
        it 'shows an alert on the page', js: true do
          visit new_project_issue_path(project)
          click_link 'Fields'

          # Wait for ajax
          find('.textile-form-field')

          travel_to(Time.now + 1.hour)

          fill_in 'item_form_field_name_0', with: 'some text'
          expect(page).to have_text('Your session has expired!. Login again to continue.')
        end
      end
    end
  end

  context 'when the user is deleted' do
    it 'forces a logout' do
      login

      user.destroy
      visit projects_path

      expect(current_path).to eq(login_path)
      expect(page).to have_content('Access denied')
    end
  end
end
