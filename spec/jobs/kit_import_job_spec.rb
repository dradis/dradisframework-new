# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KitImportJob do
  include KitUploadMacros

  before do
    @user = create(:user)
    setup_kit_import
  end

  describe '#perform' do
    after(:all) do
      cleanup_kit_import
    end

    it 'imports kit content' do
      described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

      # issue template
      expect(NoteTemplate.find('issue')).to_not be_nil

      # evidence template
      expect(NoteTemplate.find('evidence')).to_not be_nil

      # methodology template
      expect(Methodology.find('OWASPv4_Testing_Methodology')).to_not be_nil

      # project template
      expect(ProjectTemplate.find_template('dradis-template-welcome')).to_not be_nil

      # report template files
      expect(File.exist?(Rails.root.join('tmp', 'rspec', 'reports', 'word', 'dradis_welcome_template.v0.5.docm'))).to eq true
      expect(File.exist?(Rails.root.join('tmp', 'rspec', 'reports', 'excel', 'dradis_template-excel-simple.v1.3.xlsx'))).to eq true
      expect(File.exist?(Rails.root.join('tmp', 'rspec', 'reports', 'html_export', 'html_welcome_report.html.erb'))).to eq true

      # Check that no ruby file was copied
      expect(File.exist?(Rails.root.join('tmp', 'rspec', 'reports', 'word', 'dradis_welcome_template.v0.5.rb'))).to eq false
    end

    it 'can import kit without methodologies folder' do
      file = File.new(Rails.root.join('spec', 'fixtures', 'files', 'templates', 'kit_no_methodologies.zip'))
      FileUtils.cp file.path, @tmp_dir
      tmp_file = File.new(@tmp_dir.join('kit_no_methodologies.zip'))

      described_class.new.perform(tmp_file, logger: Log.new.write('Testing...'))
      expect(ProjectTemplate.find_template('dradis-template-no-methodologies')).to_not be_nil
    end

    it 'renames project templates if template with same name already exists' do
      project_template = ProjectTemplate.new(filename: 'dradis-template-welcome')
      project_template.save

      described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

      expect(ProjectTemplate.find_template('dradis-template-welcome_copy-01')).to_not be_nil
    end

    it 'renames note templates if template with same name already exists' do
      note_template = NoteTemplate.new(filename: 'evidence')
      note_template.save

      described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

      expect(NoteTemplate.find('evidence_copy-01')).to_not be_nil
    end

    it 'renames methodology templates if template with same name already exists' do
      methodology = Methodology.new(filename: 'OWASPv4_Testing_Methodology', content: '<xml/>')
      methodology.save

      described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

      expect(Methodology.find('OWASPv4_Testing_Methodology_copy-01')).to_not be_nil
    end

    if defined?(Dradis::Pro)
      it 'imports Pro-only content too' do
        described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

        # report template properties
        word_template_properties = ReportTemplateProperties.find_by(template_file: 'dradis_welcome_template.v0.5.docm')
        expect(word_template_properties).to_not be_nil
        expect(ReportTemplateProperties.find_by(template_file: 'dradis_template-excel-simple.v1.3.xlsx')).to_not be_nil
        expect(ReportTemplateProperties.find_by(template_file: 'html_welcome_report.html.erb')).to_not be_nil

        # report template properties
        expect(word_template_properties.content_blocks.keys).to match_array(['Conclusion', 'Scope'])
        expect(word_template_properties.issue_fields.map(&:name)).to match_array(['Issue Field 1', 'Issue Field 2'])
        expect(word_template_properties.evidence_fields.map(&:name)).to match_array(['Evidence Field 1', 'Evidence Field 2'])
        expect(word_template_properties.document_properties).to match_array(['dradis.project', 'dradis.client'])

        # rules engine
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus N/A CVSS to 0.0')).to_not be_nil
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus: Tag Critical')).to_not be_nil
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus: Tag High')).to_not be_nil
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus: Tag Medium')).to_not be_nil
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus: Tag Low')).to_not be_nil
        expect(Dradis::Pro::Rules::Rules::AndRule.find_by(name: 'Nessus: Tag Info')).to_not be_nil

        # sample project
        project = Project.find_by(name: 'dradis-export-welcome')
        expect(project).to_not be_nil
        expect(project.owners.first).to eq @user

        # check project RTP
        expect(project.report_template_properties).to eq(word_template_properties)
      end

      it 'renames project if project with same name already exists' do
        create(:project, name: 'dradis-export-welcome')

        described_class.new.perform(@tmp_file, logger: Log.new.write('Testing...'))

        expect(Project.last.name).to eq('dradis-export-welcome_copy-01')
      end
    end
  end
end
