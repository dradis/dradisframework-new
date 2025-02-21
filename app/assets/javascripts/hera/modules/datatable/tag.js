DradisDatatable.prototype.setupTagButtons = function () {
  if (this.$table.data('tags') === undefined) {
    return [];
  }

  // Setup tag button collection
  var tags = this.$table.data('tags'),
    tagButtons = [];

  tags.forEach(
    function (tag) {
      var tagColor = tag[1],
        tagFullName = tag[2],
        tagName = tag[0],
        $tagElement = $(
          `<i class="fa-solid fa-tag fa-fw"></i><span>${tagName}</span>`
        ).css('color', tagColor);

      tagButtons.push({
        text: $tagElement,
        action: this.tagIssue(tagFullName),
      });
    }.bind(this)
  );
  tagButtons.push(
    {
      text: $(
        `<span><i class="fa-solid fa-plus fa-fw"></i> Add new tag</span>`
      ),
      action: function () {
        $.ajax({ url: this.$table.data('new-tag-path') });
      }.bind(this),
    },
    {
      text: $(
        `<span><i class="fa-solid fa-tags fa-fw"></i> Manage Tags</span>`
      ),
      action: function () {
        window.location.href = this.$table.data('tags-path');
      }.bind(this),
    }
  );

  return tagButtons;
};

DradisDatatable.prototype.tagIssue = function (tagFullName) {
  return function () {
    var that = this;
    var selectedRows = this.dataTable.rows({ selected: true });

    selectedRows.every(function (index) {
      var row = that.dataTable.row(index),
        $tr = $(row.node()),
        url = $tr.data('tag-url');

      $.ajax({
        url: url,
        method: 'PUT',
        data: { issue: { tag_list: tagFullName } },
        dataType: 'json',
        beforeSend: function () {
          that.toggleLoadingState(row, true);
        },
        success: function (data) {
          // Replace the current tag with the new tag in the table
          $tr.find('td[data-behavior~=tag]').replaceWith($(data.tag_cell));

          // Replace the tags in the sidebar
          var itemId = $tr.attr('id').split('-')[1];
          $('#issue_' + itemId + '_link').replaceWith(data['issue_link']);

          row.deselect();
          that.toggleLoadingState(row, false);
        },
        error: function () {
          $tr
            .find('[data-behavior~=select-checkbox]')
            .html(
              '<span class="text-error ps-5" data-behavior="error-loading">Error. Try again</span>'
            );
          that.toggleLoadingState(row, false);
        },
      });
    });
  }.bind(this);
};

DradisDatatable.prototype.setupTagButtonToggle = function () {
  if (this.$table.data('tags') === undefined) {
    return;
  }

  this.dataTable.on(
    'select.dt deselect.dt',
    function () {
      var isHidden = this.dataTable.rows({ selected: true }).count() < 1;
      var tagBtn = this.dataTable.buttons('tagBtn:name');
      $(tagBtn[0].node).toggleClass('d-none', isHidden);
    }.bind(this)
  );
};
