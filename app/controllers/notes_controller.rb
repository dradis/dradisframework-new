# This controller exposes the REST operations required to manage the Note
# resource.
class NotesController < NestedNodeResourceController
  include AttachmentsCopier
  include ConflictResolver
  include LiquidEnabledResource
  include Mentioned
  include MultipleDestroy
  include NodesSidebar
  include NotificationsReader

  before_action :find_or_initialize_note
  before_action :initialize_nodes_sidebar, only: [:edit, :new, :show]
  before_action :set_auto_save_key, only: [:new, :create, :edit, :update]

  def new
    # See ContentFromTemplate concern
    @note.text = template_content if params[:template]
  end

  # Create a new Note for the associated Node.
  def create
    @note.author = current_user.email
    @note.category ||= Category.default

    if @note.save
      track_created(@note)
      redirect_to project_node_note_path(current_project, @node, @note), notice: 'Note created'
    else
      initialize_nodes_sidebar
      render 'new'
    end
  end

  # Retrieve a Note given its :id
  def show
    load_conflicting_revisions(@note)
  end

  def edit
    @versions_count = @note.versions.count
    @form_preview_path = preview_project_node_note_path(current_project, @node, @note)
  end

  # Update the attributes of a Note
  def update
    updated_at_before_save = @note.updated_at.to_i

    @note.assign_attributes(note_params)
    copy_attachments(@note) if @note.node_changed?

    if @note.save
      track_updated(@note)
      check_for_edit_conflicts(@note, updated_at_before_save)
      # if the note has just been moved to another node, we must reload
      # here so that @note.node is correct and we redirect to the right URL
      @note.reload
      redirect_to project_node_note_path(current_project, @note.node, @note), notice: 'Note updated.'
    else
      initialize_nodes_sidebar
      render 'edit'
    end
  end

  # Remove a Note from the back-end database.
  def destroy
    if @note.destroy
      track_destroyed(@note)
      redirect_to project_node_path(current_project, @node), notice: 'Note deleted'
    else
      redirect_to project_node_note_path(current_project, @node, @note), alert: 'Could not delete note'
    end
  end

  private

  # Once a valid @node is set by the previous filter we look for the Note we
  # are going to be working with based on the :id passed by the user.
  def find_or_initialize_note
    if params[:id]
      @note = @node.notes.find(params[:id])
    elsif params[:note]
      @note = @node.notes.new(note_params)
    else
      @note = @node.notes.new
    end
  end

  def liquid_resource_assigns
    { 'note' => NoteDrop.new(@note) }
  end

  def note_params
    params.require(:note).permit(:category_id, :text, :node_id)
  end

  def set_auto_save_key
    @auto_save_key = if @note&.persisted?
      "note-#{@note.id}"
    elsif params[:template]
      "node-#{@node.id}-note-#{params[:template]}"
    else
      "node-#{@node.id}-note"
    end
  end
end
