require 'rails_helper'

describe 'evidence' do
  subject { page }

  let(:issue_lib) { current_project.issue_library }

  before do
    login_to_project_as_user
    @node = create(:node, project: current_project)
  end

  example 'show page with wrong Node ID in URL' do
    node     = create(:node)
    evidence = create(:evidence, node: node)
    wrong_node = create(:node)
    expect do
      visit project_node_evidence_path(current_project, wrong_node, evidence)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe 'show page' do
    before(:each) do
      e_text    = "#[Foobar]#\nBarfoo\n\n#[Fizzbuzz]#\nBuzzfizz"
      i_text    = "#[Issue Title]#\nIssue info"
      @issue    = create(:issue,    node: @node, text: i_text)
      @evidence = create(:evidence, node: @node, issue: @issue, content: e_text)
      create_activities
      create_comments
      visit project_node_evidence_path(current_project, @node, @evidence)
    end

    let(:create_activities) { nil }
    let(:create_comments) { nil }

    it 'shows information about the Evidence' do
      should have_selector 'h5', text: 'Foobar'
      should have_selector 'p',  text: 'Barfoo'
      should have_selector 'h5', text: 'Fizzbuzz'
      should have_selector 'p',  text: 'Buzzfizz'
    end

    it "shows information about the evidence's Issue" do
      should have_selector 'h5', text: 'Issue Title'
      should have_selector 'p',  text: 'Issue info'
    end

    let(:commentable) { @evidence }
    it_behaves_like 'a page with a comments feed'

    let(:subscribable) { @evidence }
    it_behaves_like 'a page with subscribe/unsubscribe links'

    describe "clicking \'delete\'", js: true do
      let(:submit_form) do
        page.accept_confirm do
          within('.actions', match: :first) do
            find('.dots-dropdown').click
            click_link 'Delete'
          end
        end
        expect(page).to have_text "Successfully deleted evidence for '#{@evidence.issue.title}.'"
      end

      it 'deletes the Evidence' do
        id = @evidence.id
        submit_form
        #expect(page).to have_text "Successfully deleted evidence for '#{@evidence.issue.title}.'"
        expect(Evidence.exists?(id)).to be false
      end

      let(:model) { @evidence }
      include_examples 'creates an Activity', :destroy

      include_examples 'deleted item is listed in Trash', :evidence
      include_examples 'recover deleted item', :evidence
      include_examples 'recover deleted item without node', :evidence
    end

    let(:model) { @evidence }
    include_examples 'nodes pages breadcrumbs', :show, Evidence

    describe 'when including liquid content' do
      let(:record) { create(:evidence, :with_liquid, issue: @issue, node: @node) }
      include_examples 'liquid dynamic content', 'evidence', true
    end
  end

  describe 'edit page', js: true do
    let(:submit_form) { click_button 'Update Evidence' }

    before do
      issue = create(:issue, node: issue_lib)
      @evidence = create(:evidence, issue: issue, node: @node, updated_at: 2.seconds.ago)
      visit edit_project_node_evidence_path(current_project, @node, @evidence)
      click_link 'Source'
    end

    it 'has a form to edit the evidence' do
      expect(page).to have_field :evidence_content
      expect(page).to have_field :evidence_issue_id
    end

    context 'when editing the evidence from an issue' do
      it 'should redirect back to issue show page' do
        visit edit_project_node_evidence_path(current_project, @node, @evidence, return_to: 'issue')
        submit_form
        expect(page).to have_current_path(project_issue_path(current_project, @evidence.issue))
      end
    end

    describe 'submitting the form with valid information', js: true do
      let(:new_content) { 'new content' }
      before do
        click_link 'Source'
        fill_in :evidence_content, with: new_content
      end

      it 'updates the evidence' do
        submit_form
        expect(@evidence.reload.content).to eq new_content
        expect(current_path).to eq project_node_evidence_path(current_project, @node, @evidence)
      end

      let(:model) { @evidence }
      include_examples 'creates an Activity', :update

      let(:record) { @evidence }
      let(:column) { :content }
      it_behaves_like 'a page which handles edit conflicts'
    end

    describe 'submitting the form with invalid data' do
      before do
        # Manually update the textarea, otherwise we will get a timeout
        execute_script("$('#evidence_content').val('#{'a' * 65536}')")
      end

      it "doesn't update the evidence" do
        expect { submit_form }.not_to change { @evidence.reload.content }
      end

      include_examples "doesn't create an Activity"
    end

    let(:model) { @evidence }
    include_examples 'nodes pages breadcrumbs', :edit, Evidence

    describe 'local caching' do
      before do
        @issue_1 = create(:issue, node: issue_lib, text: "#[Title]#\nIssue 1")
      end

      let(:model_path) { edit_project_node_evidence_path(current_project, @node, @evidence) }
      let(:model_attributes) { [{ name: :content, value: 'Edit Evidence' }] }

      include_examples 'a form with local auto save', Evidence, :edit
    end

    describe 'when including liquid content' do
      let(:record) { create(:evidence, :with_liquid, issue: @issue, node: @node) }
      include_examples 'liquid preview', 'evidence', true
    end
  end

  describe 'new page', js: true do
    let(:tmp_path) { Rails.root.join('spec/fixtures/files/templates/') }

    let(:submit_form) { click_button 'Create Evidence' }

    before do
      allow(NoteTemplate).to receive(:pwd).and_return(tmp_path)
      @issue_0 = create(:issue, node: issue_lib, text: "#[Title]#\nIssue 0")
      @issue_1 = create(:issue, node: issue_lib, text: "#[Title]#\nIssue 1")
      visit new_project_node_evidence_path(current_project, @node, params)
      click_link 'Source'
    end

    context 'when no template is specified' do
      let(:params) { {} }

      it 'displays a blank textarea' do
        textarea = find('textarea#evidence_content')
        expect(textarea.value.strip).to eq ''
      end

      describe 'submitting the form with valid information' do
        before do
          select @issue_1.title, from: :evidence_issue_id
          fill_in :evidence_content, with: 'This is some evidence'
        end

        let(:new_evidence) { @node.evidence.order('created_at ASC').last }

        it 'creates a new piece of evidence authored by the current user' do
          expect { submit_form }.to change { @node.evidence.count }.by(1)
          expect(new_evidence.author).to eq @logged_in_as.email
          expect(new_evidence.issue).to eq @issue_1
        end

        include_examples 'creates an Activity', :create, Evidence

        it 'shows the new evidence' do
          submit_form
          expect(current_path).to eq project_node_evidence_path(current_project, @node, new_evidence)
          expect(page).to have_content 'This is some evidence'
        end
      end

      context 'submitting the form without an existing issue' do
        before do
          @issue_0.destroy
          @issue_1.destroy
          visit new_project_node_evidence_path(current_project, @node)
          expect(page).to have_content 'Auto-generate a new issue'
          fill_in :evidence_content, with: 'This is some evidence'
        end

        it 'creates a new issue' do
          expect { submit_form }.to change { Issue.count }.by(1)
        end

        it 'creates a new piece of evidence' do
          expect { submit_form }.to change { Evidence.count }.by(1)
        end

        include_examples 'creates an Activity', :create, Evidence

        it 'shows the new evidence' do
          submit_form
          expect(page).to have_content 'This is some evidence'
        end
      end
    end

    context 'when a NoteTemplate is specified' do
      let(:params)  { { template: 'sample_evidence' } }

      it 'pre-populates the textarea with the template contents' do
        click_link 'Fields'
        expect(find_field('item_form[field_name_0]').value).to include('Title')
        expect(find_field('item_form[field_value_0]').value).to include('Sample Evidence')
      end
    end

    describe 'local caching' do
      let(:model_path) { new_project_node_evidence_path(current_project, @node) }
      let(:model_attributes) { [{ name: :content, value: 'New Evidence' }] }
      let(:model_attributes_for_template) { [{ name: :content, value: 'New Evidence Template' }] }

      include_examples 'a form with local auto save', Evidence, :new
    end

    include_examples 'nodes pages breadcrumbs', :new, Evidence
  end
end
