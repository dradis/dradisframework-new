document.addEventListener "turbo:load", ->
  if ($("body.merge.new").length)

    # when clicking on the "expand/collapse" arrow icon, turn it upside down
    $(".issue-toggle").click ->
      $(this).find("i").toggleClass("fa-chevron-down fa-chevron-up")

    # handle new issue radio click
    $("input[name='new']").change ->
      # when new issue radio change, uncheck the existing issue radios too
      $("input[name='id']").prop("checked", false)

      # the "new issue" option is the only one that gets expanded when
      # selected, to prevent the user posting empty new issues
      if !$("#preview_issue_new").hasClass("in")
        $("#preview_issue_new").collapse('show')
        $(this).siblings(".issue-toggle").find("i").toggleClass("fa-chevron-down fa-chevron-up")


    # hanndle existing issue radios clicks
    $("input[name='id']").change ->
      # when existing issue radio change, uncheck the new issue radio too
      $("input[name='new']").prop("checked", false)
