# frozen_string_literal: true

class Nodes::Merger
  def self.call(target_node, source_node)
    new(target_node, source_node).call
  end

  def initialize(target_node, source_node)
    @source_node = source_node
    @target_node = target_node
  end

  def call
    Node.transaction do
      move_descendents
      reset_counter_caches
      update_properties
      copy_attachments

      Node.destroy(source_node.id)
    end
  rescue StandardError => e
    Rails.logger.error 'Node merge error occured, attempting to rectify attachments.'
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")

    undo_attachments_copy

    source_node
  end

  private

  attr_accessor :target_node, :source_node, :copied_attachments

  DESCENDENT_RELATIONSHIPS = {
    activities: :trackable_id,
    children: :parent_id,
    evidence: :node_id,
    notes: :node_id
  }.freeze

  def move_descendents
    DESCENDENT_RELATIONSHIPS.each do |relation, column|
      if relation == :activities
        source_node.send(relation).update_all(column => target_node.id)
      else
        # update_all doesn't update timestamps so we need to do it manually
        source_node.send(relation).update_all(
          column => target_node.id,
          :updated_at => Time.current
        )
      end
    end
  end

  def reset_counter_caches
    Node.reset_counters target_node.id, :children_count
  end

  def update_properties
    source_node.properties.each do |key, value|
      case key.to_sym
      when :services
        value.each do |service|
          data = service.merge(source: :merge)
          target_node.set_service data
        end
      when :services_extras
        value.each do |protocol_port, extras|
          protocol, port = protocol_port.split('/')

          extras.each do |extra|
            data = {
              extra[:id] => extra[:output],
              source: extra[:source],
              port: port.to_i,
              protocol: protocol
            }

            target_node.set_service data
          end
        end
      else
        target_node.set_property key, value
      end
    end

    target_node.save
  end

  def copy_attachments
    self.copied_attachments = []

    source_node.attachments.each do |attachment|
      copied_attachments << attachment.copy_to(target_node)
    end
  end

  def undo_attachments_copy
    return unless copied_attachments&.any?
    copied_attachments.each(&:delete)
  end
end
