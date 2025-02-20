shared_examples 'qa pages' do |item_type|
  before { allow_any_instance_of(Project).to receive(:reviewers).and_return(User.all) }

  let(:model) { item_type.to_s.classify.constantize }
  let(:states) { ['Draft', 'Published'] }

  describe 'index page', js: true do
    before do
      visit polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
    end

    it 'lists all the records that are ready for review' do
      records.each do |record|
        record_qa_path = polymorphic_path([current_project, :qa, record])
        expect(page).to have_link(record.title, href: record_qa_path)
      end
    end

    it 'redirects the user back to #show after updating the record' do
      find('.dataTable tbody tr:first-of-type').hover
      click_link 'Edit'

      expect(current_path).to eq polymorphic_path([:edit, current_project, :qa, records.first])

      click_button "Update #{item_type.to_s.titleize}"

      expect(current_path).to eq polymorphic_path([current_project, :qa, records.first])
      expect(page).to have_selector('.alert-success', text: "#{item_type.to_s.humanize} updated.")
    end

    context 'bulk update' do
      it 'is hidden by default' do
        within '.dt-buttons.btn-group' do
          expect(page).to_not have_button('State')
        end
      end

      it 'is visible when row checkbox is selected' do
        within '.dataTables_wrapper' do
          page.find('td.select-checkbox', match: :first).click
          expect(page).to have_button('State')
        end
      end

      it 'is hidden again after a row checkbox is unselected' do
        within '.dataTables_wrapper' do
          page.find('td.select-checkbox', match: :first).click
          page.find('td.select-checkbox', match: :first).click

          expect(page).to_not have_button('State')
        end
      end

      it 'updates the list of records with the state' do
        states.each do |state|
          record = model.where(state: 'ready_for_review').first
          visit polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])

          @original_row_count = page.all('tbody tr').count
          page.find('td.select-checkbox', match: :first).click

          click_button('State')
          expect do
            click_link state
            # Wait for action to complete
            page.find('.alert')
          end.to have_enqueued_job(ActivityTrackingJob).with(job_params(record))

          expect(current_path).to eq polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
          expect(page.all('tbody tr').count).to eq(@original_row_count - 1)
          expect(page).to have_selector('.alert-success', text: 'State updated successfully.')
          expect(record.reload.state).to eq state.downcase.gsub(' ', '_')
        end
      end
    end
  end

  describe 'show page' do
    before do
      visit polymorphic_path([current_project, :qa, record])
    end

    it 'parses liquid content', js: true do
      expect(page).to have_no_css('span.text-nowrap', text: 'Loading liquid dynamic content', wait: 10)

      expect(find('.note-text-inner')).to have_content("Liquid: #{record.title}")
      expect(find('.note-text-inner')).not_to have_content("Liquid: {{#{item_type.to_s}.title}}")
    end

    it 'shows the record\'s content' do
      expect(page).to have_content(record.title)
    end

    it 'updates the state' do
      states.each do |state|
        record = model.where(state: 'ready_for_review').first
        visit polymorphic_path([current_project, :qa, record])

        expect { click_button state }.to have_enqueued_job(ActivityTrackingJob).with(job_params(record))

        expect(page).to have_selector('.alert-success', text: 'State successfully updated')
        expect(record.reload.state).to eq state.downcase.gsub(' ', '_')

        next_item = model.where(state: 'ready_for_review').first

        if next_item
          expect(current_path).to eq polymorphic_path([current_project, :qa, next_item])
        else
          expect(current_path).to eq polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
        end
      end
    end
  end

  describe 'edit page' do
    before do
      visit polymorphic_path([current_project, :qa, records.first])

      within '.note-text-inner' do
        click_link 'Edit'
      end
    end

    it 'redirects the user back to #show after updating the record' do
      expect(current_path).to eq polymorphic_path([:edit, current_project, :qa, records.first])

      click_button "Update #{item_type.to_s.titleize}"

      expect(current_path).to eq polymorphic_path([current_project, :qa, records.first])
      expect(page).to have_selector('.alert-success', text: "#{item_type.to_s.humanize} updated.")
    end

    it 'redirects the user back to #show after cancelling' do
      expect(current_path).to eq polymorphic_path([:edit, current_project, :qa, records.first])

      click_link 'Cancel'

      expect(current_path).to eq polymorphic_path([current_project, :qa, records.first])
    end

    it 'redirects the user to #index after a state change' do
      expect(current_path).to eq polymorphic_path([:edit, current_project, :qa, records.first])

      click_button 'Toggle Dropdown'
      choose "#{item_type}_state_published"

      click_button "Update #{item_type.to_s.titleize}"

      expect(current_path).to eq polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
      expect(page).to have_selector('.alert-success', text: "#{item_type.to_s.humanize} updated.")
    end

    it 'renders liquid content in the editor preview', js: true do
      visit polymorphic_path([:edit, current_project, :qa, record])
      expect(find('.note-text-inner')).to have_content("Liquid: #{record.title}")
    end
  end

  describe 'reviewer role', js: true do
    context 'user is not a reviewer' do
      before do
        other_user = create(:user)
        allow_any_instance_of(Project).to receive(:reviewers).and_return(User.where(id: other_user.id))
        visit polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
      end

      it 'disables the "published" state option' do
        page.find('td.select-checkbox', match: :first).click
        click_button 'State'

        expect(page).to have_css('.dt-button.dropdown-item.disabled', text: 'Published')
      end
    end

    context 'user is a reviewer' do
      before do
        visit polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
      end

      it 'allows the "published" state option' do
        page.find('td.select-checkbox', match: :first).click
        click_button 'State'

        expect(page).to have_css('.dt-button.dropdown-item', text: 'Published')
      end
    end
  end

  def job_params(record)
    {
      action: 'state_change',
      project_id: current_project.id,
      trackable_id: record.id,
      trackable_type: record.class.to_s,
      user_id: @logged_in_as.id
    }
  end
end
