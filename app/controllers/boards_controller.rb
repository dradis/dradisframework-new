class BoardsController < AuthenticatedController
  include ActivityTracking
  include ProjectScoped

  before_action :set_board, only: [:show, :update, :destroy]
  before_action :set_node, only: [:create, :show]
  before_action :redirect_if_node_board, only: :show

  def index
    @boards    = current_project.methodology_library.boards
    @templates = Methodology.all

    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.json { render json: build_methodology_params }
    end
  end

  def show
    render layout: !request.xhr?
  end

  def create
    if params[:use_template] == 'yes'
      begin
        # check template param
        unless Methodology.all.map(&:filename).include?(params[:template])
          raise 'Unknown template'
        end

        methodology = Methodology.find(params[:template])

        if methodology.version == 1
          migration = MethodologyMigrationService.new(current_project.id)
          migration.migrate(methodology, board_name: board_params[:name], node: @node)
        elsif methodology.version >= 2
          importer = MethodologyImportService.new(current_project.id)
          importer.import(methodology, board_name: board_params[:name], node: @node)
        end

        board = Board.last
        track_created(board)
        redirect_to [current_project, board], notice: 'Methodology added.'
      rescue Exception => e
        logger.error e.message
        redirect_to project_boards_path(current_project), alert: "#{e.message}"
      end
    else
      @board = current_project.boards.new(board_params)

      if @board.save
        track_created(@board)

        list1 = @board.lists.create name: 'To Do'
        list2 = @board.lists.create name: 'In Progress', previous_list: list1
        @board.lists.create name: 'Done', previous_list: list2

        redirect_to [current_project, @board], notice: 'Methodology added.'
      else
        redirect_to project_boards_path(current_project), alert: @board.errors.full_messages.join('; ')
      end
    end
  end

  def update
    if @board.update(board_params)
      track_updated(@board)
      redirect_to [current_project, @board], notice: 'Methodology renamed.'
    else
      redirect_to project_boards_path(current_project), alert: @board.errors.full_messages.join('; ')
    end
  end

  def destroy
    if @board.destroy
      track_destroyed(@board)
      redirect_to project_boards_path(current_project), notice: 'Methodology deleted.'
    else
      redirect_to project_boards_path(current_project), notice: "Error deleting methodology: #{@board.errors.full_message.join('; ')}"
    end
  end

  private

  def board_params
    params.require(:board).permit(:name, :node_id)
  end

  def build_methodology_params
    @boards.map do |board|
      next if board.lists.empty?
      board_data = {
        id: board.id,
        name: board.name,
        total: board.cards.count,
        url: project_board_path(current_project, board)
      }
      lists = board.lists.map do |list|
        { category: list.name, value: list.cards.count }
      end
      [board_data, lists]
    end.compact
  end

  # Redirect to the node for boards under nodes.
  def redirect_if_node_board
    if @node && @node.type_id != Node::Types::METHODOLOGY && !request.xhr?
      redirect_to project_node_path(
        current_project,
        @node,
        tab: 'methodology-tab'
      )
    end
  end

  def set_board
    @board = current_project.boards.find(params[:id])
  end

  def set_node
    @node =
      if @board.present?
        @board.node
      elsif (node_id = params.dig(:board, :node_id)).present?
        current_project.nodes.find(node_id)
      end
  end
end
