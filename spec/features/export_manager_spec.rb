require 'rails_helper'

describe 'Export Manager' do
  before { login_to_project_as_user }

  it 'presents the name of the project you are exporting' do
    visit project_export_manager_path(current_project)
    expect(page).to have_content(current_project.name)
  end

  context 'Submit button' do
    context 'when there are only draft records in the project' do
      it 'presents the option to export all records' do
        create(:issue, node: current_project.issue_library, state: :draft)
        visit project_export_manager_path(current_project)
        expect(page).to have_content('Export All Records')
      end
    end

    context 'when there are published records in the project' do
      it 'presents the option to export published records' do
        create(:issue, node: current_project.issue_library, state: :published)
        visit project_export_manager_path(current_project)
        expect(page).to have_content('Export Published Records')
      end
    end
  end

  context 'a template is passed to the export action' do
    module FakeExport
      module Actions
        def fake
          render text: params.to_yaml
        end
      end
    end
    ExportController.class_eval %( include FakeExport::Actions )

    pending "discards invalid templates (not in the plugin's template folder)" do
      visit url_for({ controller: :export, action: :fake, template: 'foobar' })

      # The dummy Export plugin returns a YAML representation of every parameter
      # that it receives. The ExportController should catch the rogue :template
      # parameter and delete it before passing it along
      expect(page).to_not have_content('foobar')
    end

    pending 'allows through valid templates' do
      tmp_reports = Pathname.new('tmp/templates/reports')
      FileUtils.mkdir_p(tmp_reports)
      allow(Configuration).to receive(:paths_templates_reports).and_return(tmp_reports)

      FileUtils.mkdir(tmp_reports.join('fake_export'))
      FileUtils.touch(tmp_reports.join('fake_export/valid_template'))

      visit url_for({ controller: :export, action: :fake, template: 'valid_template' })

      # The dummy Export plugin returns a YAML representation of every parameter
      # that it receives. The ExportController should detect the valid :template
      # parameter and passing it along to the plugin
      expect(page).to have_content('valid_template')

      FileUtils.rm_rf('tmp/templates/')
    end
  end
end
