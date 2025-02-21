shared_examples 'a form with a help button' do
  describe "clicking the 'help' button", js: true do
    before { find('form .btn-help').click }
    it 'displays Textile help' do
      expect(page).to have_selector 'h5', text: /Text styles/i
      expect(page).to have_selector 'h5', text: /Block Code \(bc.\)/i
      expect(page).to have_selector 'h5', text: /Lists/i
      expect(page).to have_selector 'h5', text: /Miscellaneous/i
      expect(page).to have_selector 'h5', text: /Further help/i
    end
  end
end

shared_examples 'an editor that remembers what view you like' do
  before do
    visit action_path
  end

  it 'will load source view after using source view' do
    click_link 'Source'

    visit action_path

    expect(page).to have_css('textarea.textile')
  end

  it 'will load fields view after viewing source view but clicking back to fields view' do
    click_link 'Source'
    click_link 'Fields'

    visit action_path

    expect(page).to have_css('.textile-form')
  end
end

shared_examples 'a textile form view' do |klass|
  before do
    visit action_path

    required_form if defined?(required_form)

    click_link 'Fields'
  end

  it 'add fields in the form', js: true do
    current_field_count = all('.textile-form-field').count

    within '.textile-form' do
      click_link 'Add field'
    end

    expect(page).to have_css('.textile-form-field', count: current_field_count + 1)
  end

  it 'remove fields in the form', js: true do
    expect {
      find('[data-behavior=textile-form-field]', match: :first).hover
      within '[data-behavior~=textile-form-field]', match: :first do
        click_link 'Delete'
      end
    }.to change { all('.textile-form-field').count }.by(-1)
  end

  it 'saves the item when submitted', js: true do
    fill_in('item_form[field_name_0]', with: 'Title')
    fill_in('item_form[field_value_0]', with: 'Test Item')

    # Wait for the source view change buffer time
    find('.textile-preview', text: /Test Item/)

    within '.form-actions' do
      find('[type="submit"]').click
    end

    updated_item = defined?(item) ? item : klass.last

    content_attribute = get_content_attribute(klass)
    show_path = get_show_path(updated_item, klass)

    expect(updated_item.reload.send(content_attribute)).to include("#[Title]#\r\nTest Item")
    expect(page).to have_current_path(polymorphic_path(show_path), ignore_query: true)
  end

  it 'supports text without field headers' do
    content_attribute = get_content_attribute(klass)
    fieldless_string = "Line 1\nLine 2\n\nLine 4"
    field_string = "#[Field]#\nTest Value"

    click_link 'Source'
    fill_in "#{klass.to_s.downcase}_#{content_attribute}", with: fieldless_string + "\n" + field_string

    click_link 'Fields'

    expect(find('#item_form_field_name_0').value).to eq ('')
    expect(find('#item_form_field_value_0').value).to eq (fieldless_string)
    expect(find('#item_form_field_name_1').value).to eq ('Field')
    expect(find('#item_form_field_value_1').value).to eq ('Test Value')
  end

  it 'supports fields with duplicated field names' do
    content_attribute = get_content_attribute(klass)
    text = "#[Field]#\nValue 1\n\n#[Field]#\nValue 2"

    click_link 'Source'
    fill_in "#{klass.to_s.underscore}_#{content_attribute}", with: text

    click_link 'Fields'

    expect(find('#item_form_field_name_0').value).to eq ('Field')
    expect(find('#item_form_field_value_0').value).to eq ('Value 1')
    expect(find('#item_form_field_name_1').value).to eq ('Field')
    expect(find('#item_form_field_value_1').value).to eq ('Value 2')
  end

  def get_content_attribute(klass)
    if klass == Evidence
      content_attribute = :content
    elsif klass == Issue || klass == Note
      content_attribute = :text
    elsif klass == Card
      content_attribute = :description
    end
  end

  def get_show_path(updated_item, klass)
    if klass == Evidence || klass == Note
      show_path = [current_project, updated_item.node, updated_item]
    elsif klass == Issue
      show_path = [current_project, updated_item]
    elsif klass == Card
      show_path = [current_project, updated_item.list.board, updated_item.list, updated_item]
    end
  end
end
