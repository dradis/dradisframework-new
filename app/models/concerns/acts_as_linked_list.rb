module ActsAsLinkedList
  extend ActiveSupport::Concern

  def first_item
    @first_item ||= self.items.find_by(previous_id: nil)
  end

  def last_item
    @last_item ||= self.ordered_items.last
  end

  def ordered_items
    return [] if first_item.nil?

    current_item = first_item
    items = [current_item]
    while (next_item = self.items.find_by(previous_id: current_item.id)) do
      items << next_item
      current_item = next_item
    end

    items
  end

  class_methods do
    def list_item_name(name)
      names = name.to_s.pluralize

      # alias_attribute :items, names.to_sym
      # Rails 7.2 deprecated non-attribute alias_attributes: https://github.com/rails/rails/pull/48972
      # There may be an update coming for this: https://github.com/rails/rails/pull/49801
      # But it has not yet been merged. Until then, we must define the association again here:
      has_many :items, class_name: name.to_s.titleize

      alias_method "first_#{name}".to_sym, :first_item
      alias_method "last_#{name}".to_sym, :last_item
      alias_method "ordered_#{names}".to_sym, :ordered_items
    end

    # Public: Moves an item to a new position by passing the new previous and
    #   the new next items.
    #
    # item - The item to be moved.
    # new_position - The hash that contains the new previous and/or new next
    #   item using the keys :prev_item and :next_item, respectively.
    #
    # Returns true.
    def move(item, new_position = {})
      item.class.transaction do
        next_item = item.send("next_#{item.class.name.downcase}")

        # Update previous position
        next_item.update_attribute(:previous_id, item.previous_id) if next_item

        # Update new position
        new_previous = new_position[:prev_item]
        new_next = new_position[:next_item]
        if new_previous
          item.update_attribute(:previous_id, new_previous.id)
        else
          item.update_attribute(:previous_id, nil)
        end

        new_next.update_attribute(:previous_id, item.id) if new_next
      end
    end
  end
end
