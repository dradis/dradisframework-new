require 'rails_helper'

describe 'Pro export template' do
  before { login_to_project_as_user }

  let(:export_options) {
    { plugin: Dradis::Plugins::Projects, project_id: current_project.id }
  }

  context 'exporting boards' do
    before do
      @boards_library = current_project.methodology_library
      @project_board = create(
        :board,
        project: current_project,
        node: @boards_library
      )
      @node = create(:node, project: current_project)
      @node_board = create(:board, project: current_project, node: @node)

      @exporter =
        Dradis::Plugins::Projects::Export::V3::Template.new(export_options)

      @result = @exporter.export
    end

    it 'creates the project board xml' do
      project_board_xml = "<board version=\"3\">\<id>#{@project_board.id}</id>"\
      "<name>#{@project_board.name}</name><node_id>#{@project.methodology_library.id}</node_id></board>"

      expect(@result).to include(project_board_xml)
    end

    it 'creates the node board xml' do
      node_board_xml = "<board version=\"3\"><id>#{@node_board.id}</id>"\
      "<name>#{@node_board.name}</name>"\
      "<node_id>#{@node.id}</node_id></board>"

      expect(@result).to include(node_board_xml)
    end
  end
end

