require 'rails_helper'

describe 'note pages' do
  subject { page }

  include ActivityMacros

  let(:tmp_path) { Rails.root.join('spec/fixtures/files/note_templates/') }

  before do
    # avoid messing around with any existing templates:
    allow(NoteTemplate).to receive(:pwd).and_return(tmp_path)
    login_to_project_as_user
    @node = create(:node, project: current_project)
  end

  example 'show page with wrong Node ID in URL' do
    node       = create(:node, project: current_project)
    note       = create(:note, node: node)
    wrong_node = create(:node, project: current_project)
    expect do
      visit project_node_note_path(current_project, wrong_node, note)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe 'show page' do
    before do
      text = "#[Title]#\nMy note\n\n#[Description]#\nMy description"
      @note = create(:note, node: @node, text: text)
      create_activities
      create_comments
      visit project_node_note_path(current_project, @node, @note)
    end

    let(:create_activities) { nil }
    let(:create_comments) { nil }

    it "shows the note's contents" do
      should have_selector 'h5', text: 'Title'
      should have_selector 'p',  text: 'My note'
      should have_selector 'h5', text: 'Description'
      should have_selector 'p',  text: 'My description'
    end

    let(:commentable) { @note }
    it_behaves_like 'a page with a comments feed'

    let(:subscribable) { @note }
    it_behaves_like 'a page with subscribe/unsubscribe links'

    describe "clicking 'delete'", js: true do
      let(:submit_form) do
        page.accept_confirm do
          within('.actions', match: :first) do
            find('.dots-dropdown').click
            click_link 'Delete'
          end
        end
        expect(page).to have_text 'Note deleted'
      end

      it "deletes the note and redirects to the node's page" do
        id = @note.id
        submit_form
        expect(Note.find_by_id(id)).to be_nil
        expect(current_path).to eq project_node_path(@node.project, @node)
      end

      let(:model) { @note }
      include_examples 'creates an Activity', :destroy

      include_examples 'deleted item is listed in Trash', :note
      include_examples 'recover deleted item', :note
      include_examples 'recover deleted item without node', :note
    end

    let(:model) { @note }
    include_examples 'nodes pages breadcrumbs', :show, Note

    let(:record) { create(:note, node: @node, content: "#[Title]#\nTitle\n\n#[Description]#\nLiquid: {{note.fields['Title']}}") }
    include_examples 'liquid dynamic content', :note, true
  end

  describe 'edit page', js: true do
    before do
      @note = create(:note, node: @node, updated_at: 2.seconds.ago)
      visit edit_project_node_note_path(current_project, @node, @note)
      click_link 'Source'
    end

    let(:submit_form) { click_button 'Update Note' }
    let(:cancel_form) { click_link 'Cancel' }

    it 'has a form to edit the note' do
      should have_field :note_text
    end

    it 'uses the full-screen editor plugin' # TODO

    it_behaves_like 'a form with a help button'

    describe 'textile form view' do
      let(:action_path) { edit_project_node_note_path(current_project, @node, @note) }
      let(:item) { @note }
      it_behaves_like 'a textile form view', Note
      it_behaves_like 'an editor that remembers what view you like'
    end

    # TODO handle the case where a Note has no paperclip versions (legacy data)

    describe 'submitting the form with valid information', js: true do
      let(:new_content) { 'New note text' }
      before do
        click_link 'Source'
        fill_in :note_text, with: new_content
      end

      it 'updates the note' do
        submit_form
        expect(@note.reload.text).to eq new_content
      end

      it 'shows the updated note' do
        submit_form
        expect(current_path).to eq project_node_note_path(current_project, @node, @note)
        expect(page).to have_content new_content
      end

      let(:model) { @note }
      include_examples 'creates an Activity', :update

      let(:column) { :text }
      let(:record) { @note }
      it_behaves_like 'a page which handles edit conflicts'
    end

    context 'submitting the form with invalid information' do
      before do
        # Manually update the textarea, otherwise we will get a timeout
        execute_script("$('#note_text').val('#{'a' * 65536}')")
      end

      # TODO how to handle conflicting edits in this case?

      it "doesn't update the note" do
        expect { submit_form }.not_to change { @note.reload.text }
      end

      include_examples "doesn't create an Activity"
    end

    describe 'cancel button' do
      it 'returns to the note page' do
        cancel_form
        expect(page).to have_current_path(project_node_note_path(current_project, @node, @note))
      end
    end

    let(:model) { @note }
    include_examples 'nodes pages breadcrumbs', :edit, Note

    describe 'local caching' do
      let(:model_path) { edit_project_node_note_path(current_project, @node, @note) }
      let(:model_attributes) { [{ name: :text, value: 'Edit Note' }] }

      include_examples 'a form with local auto save', Note, :edit
    end
  end

  describe 'new page', js: true do
    before do
      visit new_project_node_note_path(current_project, @node, params)
      click_link 'Source'
    end

    let(:submit_form) { click_button 'Create Note' }
    let(:cancel_form) { click_link 'Cancel' }

    context 'when no template is specified' do
      let(:params) { {} }

      it 'displays a blank textarea' do
        textarea = find('textarea#note_text')
        expect(textarea.value.strip).to eq ''
      end

      it 'uses the textile-editor plugin'

      it_behaves_like 'a form with a help button'

      describe 'submitting the form with valid information' do
        let(:new_note) { @node.notes.order('created_at ASC').last }

        before do
          # "fill_in :note_text" doesn't work for some reason :(
          find('#note_text').set('This is a note')
        end

        it 'creates a new note from the current user' do
          expect { submit_form }.to change { @node.notes.count }.by(1)
          expect(new_note.author).to eq @logged_in_as.email
        end

        it 'shows the newly created note' do
          submit_form
          expect(current_path).to eq project_node_note_path(current_project, @node, new_note)
          expect(page).to have_content 'This is a note'
        end

        include_examples 'creates an Activity', :create, Note
      end

      describe 'submitting the form with invalid information' do
        before do
          # Manually update the textarea, otherwise we will get a timeout
          execute_script("$('#note_text').val('#{'a' * 65536}')")
        end

        it "doesn't create a note" do
          expect { submit_form }.not_to change { Note.count }
        end

        include_examples "doesn't create an Activity"
      end

      describe 'cancel button' do
        it 'returns to the node page' do
          cancel_form
          expect(page).to have_current_path(project_node_path(current_project, @node))
        end
      end
    end

    context 'when a NoteTemplate is specified' do
      let(:params)  { { template: 'simple_note' } }

      it 'pre-populates the textarea with the template contents' do
        click_link 'Fields'
        expect(find_field('item_form[field_name_0]').value).to include('IPAddress')
        expect(find_field('item_form[field_value_0]').value).to include('127.0.0.1')
      end
    end

    describe 'textile form view' do
      let(:params) { {} }

      let(:action_path) { new_project_node_note_path(current_project, @node) }
      it_behaves_like 'a textile form view', Note
      it_behaves_like 'an editor that remembers what view you like'
    end

    describe 'local caching' do
      let(:model_path) { new_project_node_note_path(current_project, @node) }
      let(:model_attributes) { [{ name: :text, value: 'New Note' }] }
      let(:model_attributes_for_template) { [{ name: :text, value: 'New Note Template' }] }

      include_examples 'a form with local auto save', Note, :new
    end

    include_examples 'nodes pages breadcrumbs', :new, Note
  end
end
