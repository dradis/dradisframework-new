module QAHelper
  def button_text_for(state)
    case state
    when 'draft'
      'Still not ready for review or the report.'
    when 'ready_for_review'
      'All done on this one, ready for QA.'
    when 'published'
      'Content is final, ready for the report.'
    end
  end

  def label_options_for(state)
    if state == 'published' && !can?(:publish, current_project)
      {
        data: {
          bs_toggle: 'tooltip',
          bs_title: 'You are not a Reviewer for this project.'
        }
      }
    else
      {}
    end
  end

  def radio_button_for(form_helper)
    is_disabled = form_helper.value == 'published' && !can?(:publish, current_project)

    form_helper.radio_button(
      class: 'd-none',
      data: { behavior: 'state-radio' },
      disabled: is_disabled
    )
  end
end
