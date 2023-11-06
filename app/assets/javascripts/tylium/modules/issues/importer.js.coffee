# IssueImporter
#
# This object handles making server requests to search for issues, presenting
# the results and adding them to the library.

@IssueImporter =
  submit: (path, issue_text, state) ->
    $.post path, { 
      issue: {
        text: issue_text, 
        state: state
      }
    }

document.addEventListener "turbo:load", ->
  if $('#issues').length
    # Detect if we're displaying results of a query and toggle the widget
    if $('.results').length
      $('.import-toggle').click();
      $('.import-box').find("input:text[value!='']").focus();

    # Clicking on 'add-issue' triggers a call to Issues#create
    $('.results').on 'click', '[data-behavior~=add-issue]', (e) ->
      issueTitle = $(this).parents('tr').find('td:first-child').text()

      e.preventDefault()
      IssueImporter.submit $(this).attr('href'), $(this).data('text'), $(this).data('state')
      $(this).parents('tr').remove()

      # Show confirmation
      $('[data-behavior~=success-alert]').remove()
      $("
      <div class='alert alert-success' data-behavior='success-alert'>#{issueTitle} issue added.</div>
      ").insertAfter($('[data-behavior~=project-teaser]'));
