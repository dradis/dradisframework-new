require 'rails_helper'

describe 'Issues pages' do
  subject { page }

  it 'should require authenticated users' do
    visit project_issues_path(create(:project))
    expect(current_path).to eq(login_path)
    expect(page).to have_content('Access denied.')
  end

  context 'as authenticated user' do

    before { login_to_project_as_user }

    context 'with an Issue library' do
      let(:issuelib) { current_project.issue_library }

      describe 'index page' do
        it 'presents a link to add new issue' do
          visit project_issues_path(current_project)
          expect(page).to have_xpath("//a[@href='#{new_project_issue_path(current_project)}']")
        end

        it 'shows an *empty list* message if none have been assigned' do
          visit project_issues_path(current_project)
          expect(current_path).to eq(project_issues_path(current_project))
          expect(page).to have_content('nothing yet')
        end

        it 'presents a list of all existing issues in the library' do
          list = ['Directory listings', 'Out-of-date Apache', 'Clear-text protocols']
          list.each do |title|
            issuelib.notes.create(
              category: Category.issue,
              author: 'rspec',
              text: "#[Title]#\n#{title}\n\n#[Description]#\nFoobar\n\n"
            )
          end

          visit project_issues_path(current_project)
          expect(current_path).to eq(project_issues_path(current_project))
          list.each do |title|
            expect(page).to have_content(title)
          end
        end

        context 'bulk state update', js: true do
          it 'updates the list of records with the state' do
            issue = create(:issue, node: current_project.issue_library)
            new_state = 'Ready for review'

            visit project_issues_path(current_project)

            within '.dataTables_wrapper' do
              page.find('td.select-checkbox', match: :first).click
              click_button('State')
              click_link(new_state)
            end

            expect(page).to have_selector('.alert-success', text: 'State updated successfully.')
            expect(issue.reload.state).to eq new_state.downcase.gsub(' ', '_')
            within 'tbody tr', match: :first do
              expect(page).to have_content(new_state)
            end
          end
        end
      end

      describe 'new page', js: true do
        let(:submit_form) { click_button 'Create Issue' }

        context 'submitting the form with valid information' do
          before do
            visit new_project_issue_path(current_project)
            click_link 'Source'
            fill_in :issue_text,
              with: "#[Title]#\nRspec issue\n\n#[Description]#\nNew description\n\n"
          end

          it 'creates a new Issue under the Issue library with the right Category and Author'  do
            expect { submit_form }.to change { current_project.issues.count }.by(1)
            issue = current_project.issues.last
            expect(current_path).to eq(project_issue_path(current_project, issue))
            expect(page).to have_content('Rspec issue')

            expect(issue.category).to eq(Category.issue)
            expect(issue.author).to eq(@logged_in_as.email)
          end

          include_examples 'creates an Activity', :create, Issue

          context 'with states' do
            it 'creates a new draft Issue' do
              expect { submit_form }.to change { current_project.issues.count }.by(1)
              issue = current_project.issues.last
              expect(issue.state).to eq('draft')
            end

            it 'creates a new ready for review Issue' do
              within '.btn-states' do
                click_button 'Toggle Dropdown'
                find('p[data-behavior="state-label"]', text: 'Ready for review').click
              end
              expect { submit_form }.to change { current_project.issues.count }.by(1)
              issue = current_project.issues.last
              expect(issue.state).to eq('ready_for_review')
            end

            it 'creates a new published Issue' do
              within '.btn-states' do
                click_button 'Toggle Dropdown'
                find('p[data-behavior="state-label"]', text: 'Published').click
              end
              expect { submit_form }.to change { current_project.issues.count }.by(1)
              issue = current_project.issues.last
              expect(issue.state).to eq('published')
            end
          end
        end

        context 'submitting the form with invalid information' do
          before do
            visit new_project_issue_path(current_project)
            click_link 'Source'

            # Manually update the textarea, otherwise we will get a timeout
            execute_script("$('#issue_text').val('#{'a' * 65536}').trigger('textchange');")
          end

          it "doesn't create a new Issue" do
            expect { submit_form }.not_to change { current_project.issues.count }
          end

          include_examples "doesn't create an Activity"

          it 'shows the form again with an error message' do
            submit_form
            should have_selector '.alert.alert-danger'
          end
        end

        context 'when passed a note template', js: true do
          it 'preloads the editor with the template' do
            template_path = Rails.root.join('spec/fixtures/files/note_templates/')
            allow(NoteTemplate).to receive(:pwd).and_return(template_path)

            template_content = File.read(template_path.join('simple_note.txt'))
            visit new_project_issue_path(current_project, template: 'simple_note')

            expect(find_field('item_form[field_name_0]').value).to include('IPAddress')
            expect(find_field('item_form[field_name_1]').value).to include('Hostname')
            expect(find_field('item_form[field_name_2]').value).to include('OS')
            expect(page).to have_select('item_form[field_value_2]')
          end
        end

        context 'when the issue has a Tags field' do
          it 'tags the issue with the corresponding tag if only one is present' do
            tag_field = '!f89406_private'
            visit new_project_issue_path(current_project)
            click_link 'Source'
            fill_in :issue_text,
              with: "#[Title]#\nRspec issue\n\n#[Tags]#\n#{tag_field}\n\n"

            expect { submit_form }.to change { current_project.issues.count }.by(1)
            issue = current_project.issues.last
            expect(issue.tags.count).to eq(1)
            expect(issue.tag_list).to eq(tag_field)
          end

          it 'tags the issue with the first tag if more than one are present' do
            tag_field = '!f89406_private, !468847_public'
            visit new_project_issue_path(current_project)
            click_link 'Source'
            fill_in :issue_text,
              with: "#[Title]#\nRspec issue\n\n#[Tags]#\n#{tag_field}\n\n"

            expect { submit_form }.to change { current_project.issues.count }.by(1)
            issue = current_project.issues.last
            expect(issue.tags.count).to eq(1)
            expect(issue.tag_list).to eq(tag_field.split(', ').first)
          end
        end

        describe 'local caching' do
          let(:add_tags) do
            @tag_1 = current_project.tags.create(name: '!9467bd_critical')
            @tag_2 = current_project.tags.create(name: '!d62728_high')
          end

          let(:model_path) { new_project_issue_path(current_project) }
          let(:model_attributes) { [{ name: :text, value: 'New Issue' }] }
          let(:model_attributes_for_template) { [{ name: :text, value: 'New Issue Template' }] }

          include_examples 'a form with local auto save', Issue, :new
        end
      end

      describe 'edit page', js: true do
        let(:submit_form) { click_button 'Update Issue' }

        before do
          issuelib = current_project.issue_library
          @issue = create(:issue, node: issuelib, updated_at: 2.seconds.ago)
          visit edit_project_issue_path(current_project, @issue)
          click_link 'Source'
        end

        describe 'submitting the form with valid information' do
          let(:field) { '#[Description]#' }
          let(:value) { 'New info' }
          let(:new_content) { "#{field}\r\n#{value}" }

          before do
            fill_in :issue_text, with: field
            find('#issue_text').send_keys :enter, value
          end

          let(:submit_form) { click_button 'Update Issue' }

          it 'updates and shows the issue' do
            submit_form
            expect(@issue.reload.text).to eq new_content
            expect(current_path).to eq project_issue_path(current_project, @issue)
          end

          let(:model) { @issue }
          include_examples 'creates an Activity', :update

          it "creates a version with the user's email as 'whodunnit'" do
            with_versioning do
              submit_form
              expect(@issue.reload.versions.last.whodunnit).to eq @logged_in_as.email
            end
          end

          context 'with states' do
            it 'updates the issue\'s state to draft' do
              within '.btn-states' do
                click_button 'Toggle Dropdown'
                find('p[data-behavior="state-label"]', text: 'Draft').click
              end
              submit_form
              expect(@issue.reload.state).to eq('draft')
            end

            it 'updates the issue\'s state to ready for review' do
              within '.btn-states' do
                click_button 'Toggle Dropdown'
                find('p[data-behavior="state-label"]', text: 'Ready for review').click
              end
              submit_form
              expect(@issue.reload.state).to eq('ready_for_review')
            end

            it 'updates the issue\'s state to published' do
              @issue = create(:issue, node: issuelib, updated_at: 2.seconds.ago, state: 'draft')
              visit edit_project_issue_path(current_project, @issue)

              within '.btn-states' do
                click_button 'Toggle Dropdown'
                find('p[data-behavior="state-label"]', text: 'Published').click
              end
              submit_form
              expect(@issue.reload.state).to eq('published')
            end
          end

          let(:column) { :text }
          let(:record) { @issue }
          it_behaves_like 'a page which handles edit conflicts'
        end

        context 'submitting the form with invalid information' do
          before do
            # Manually update the textarea, otherwise we will get a timeout
            execute_script("$('#issue_text').val('#{'a' * 65536}').trigger('textchange');")
          end

          it "doesn't update the issue" do
            expect { submit_form }.not_to change { @issue.reload.text }
          end

          include_examples "doesn't create an Activity"

          it 'shows the form again with an error message' do
            submit_form
            should have_selector '.alert.alert-danger'
          end
        end

        describe 'local caching' do
          let(:add_tags) do
            @tag_1 = current_project.tags.create(name: '!9467bd_critical')
            @tag_2 = current_project.tags.create(name: '!d62728_high')
          end

          let(:model_path) { edit_project_issue_path(current_project, @issue) }
          let(:model_attributes) { [{ name: :text, value: 'Edit Issue' }] }

          include_examples 'a form with local auto save', Issue, :edit
        end

        describe 'when including liquid content' do
          let(:record) { create(:issue, :with_liquid, node: issuelib) }
          include_examples 'liquid preview', 'issue', false
        end
      end

      describe 'show page' do
        before do
          @issue = issuelib.notes.create(
            category: Category.issue,
            author: 'rspec',
            text: "#[Title]#\nMultiple Apache bugs\n\n",
            node: create(:node, :with_project)
          )
          # @issue is currently loaded as a Note, not an Issue. Make sure it
          # has the right class:
          @issue = Issue.find(@issue.id)
          extra_setup
          visit project_issue_path(current_project, @issue)
        end

        let(:extra_setup) do
          create_activities
          create_comments
        end
        let(:create_activities) { nil }
        let(:create_comments) { nil }

        context 'when there are host nodes with evidence' do
          let(:extra_setup) do
            host1 = create(:node, label: '10.0.0.1', project: current_project, type_id: Node::Types::HOST)
            host1.evidence.create(
              author: 'rspec',
              issue_id: @issue.id,
              content: "#[EvidenceBlock1]#\nThis apache is old!"
            )

            host2 = create(:node, label: '10.0.0.2', project: current_project, type_id: Node::Types::HOST)
            3.times do |i|
              host2.evidence.create(
                author: 'rspec',
                issue_id: @issue.id,
                content: "#[EvidenceBlock1]#\nThis apache is old (#{i})!",
                node: create(:node, project: current_project)
              )
            end
          end

          it 'presents the table of hosts affected by a given issue', js: true do
            click_link 'Evidence'
            expect(page).to have_selector('[data-behavior~=dradis-datatable]')
            expect(find('#evidence-tab')).to have_content('10.0.0.1')
            expect(find('#evidence-tab')).to have_content('10.0.0.2', count: 3)
          end

          it 'presents the evidence of the other nodes on click', js: true do
            skip "enable when we move out from PhantomJS and support js 'fetch'"
            click_link 'Evidence'
            click_link '10.0.0.2 (3)'
            expect(page).to have_content('This apache is old (0)!')
          end
        end

        let(:commentable) { @issue }
        it_behaves_like 'a page with a comments feed'

        let(:subscribable) { @issue }
        it_behaves_like 'a page with subscribe/unsubscribe links'

        describe "clicking 'delete'", js: true do
          before { visit project_issue_path(current_project, @issue) }

          let(:submit_form) do
            page.accept_confirm do
              within('.actions', match: :first) do
                find('.dots-dropdown').click
                click_link 'Delete'
              end
            end
            expect(page).to have_text 'Issue deleted.' # forces waiting
          end

          it 'deletes the issue' do
            id = @issue.id
            submit_form
            expect(Issue.exists?(id)).to be false
          end

          let(:model) { @issue }
          include_examples 'creates an Activity', :destroy

          include_examples 'deleted item is listed in Trash', :issue
          include_examples 'recover deleted item', :issue
        end

        context 'with states' do
          it 'shows the issue states in the view' do
            expect(page).to have_text "(#{@issue.state.humanize})"
          end
        end

        describe 'when including liquid content' do
          let(:record) { create(:issue, :with_liquid, node: issuelib) }
          include_examples 'liquid dynamic content', 'issue', false
        end
      end
    end

    describe 'revision history' do
      let(:issue) do
        issue = create(:issue, node: node, text: 'issue text')
        issue.update(text: 'updated text')
        issue
      end

      before { PaperTrail.enabled = true }
      after { PaperTrail.enabled = false }

      context 'issue belonging to current project' do
        let(:node) { current_project.issue_library }

        it 'can view issue revisions' do
          issue.update(text: 'updated text')

          visit project_issue_revisions_path(current_project, issue)

          within '.js-diff-body' do
            expect(page).to have_text('issue[0m[32mupdated[0m text') # match the format of the inline diff
          end
        end
      end

      context 'issue belonging to another project' do
        let(:node) do
          create(
            :node,
            label: 'Other project all issues',
            type_id: Node::Types::ISSUELIB
          )
        end

        it 'cannot view issue revisions' do
          visit project_issue_revisions_path(current_project, issue)
          expect(page).to have_text('Record not found')
        end
      end
    end
  end
end
