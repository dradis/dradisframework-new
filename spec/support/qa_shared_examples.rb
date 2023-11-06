shared_examples 'qa pages' do |item_type|
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

    it 'redirects the user back to #index after updating the record' do
      find('.dataTable tbody tr:first-of-type').hover
      click_link 'Edit'

      expect(page).to have_current_path(polymorphic_path([:edit, current_project, :qa, records.first]))

      click_button "Update #{item_type.to_s.titleize}"

      expect(current_path).to eq polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
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

    it 'shows liquid content' do
      expect(find('.note-text-inner')).to have_content("Liquid: #{record.fields["Title"]}")
      expect(find('.note-text-inner')).not_to have_content("Liquid: {{#{item_type}.fields['Title']}}")
    end

    it 'shows the record\'s content' do
      expect(page).to have_content(record.title)
    end

    it 'updates the state' do
      states.each do |state|
        record = model.where(state: 'ready_for_review').first
        visit polymorphic_path([current_project, :qa, record])

        expect { click_button state }.to have_enqueued_job(ActivityTrackingJob).with(job_params(record))

        expect(current_path).to eq polymorphic_path([current_project, :qa, item_type.to_s.pluralize.to_sym])
        expect(page).to have_selector('.alert-success', text: 'State updated successfully.')
        expect(record.reload.state).to eq state.downcase.gsub(' ', '_')
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
