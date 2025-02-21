DradisDatatable.prototype.setupCheckboxListeners = function() {
  var that = this,
      $selectAllBtn = $(this.dataTable.buttons('#select-all').nodes()[0]);

  this.dataTable.on('select.dt deselect.dt', function() {
    if (that.areAllSelected()) {
      $selectAllBtn.find('#select-all-checkbox').prop({'checked': true, 'indeterminate': false});
    }
    else if (that.dataTable.rows({selected:true}).count() > 0) {
      $selectAllBtn.find('#select-all-checkbox').prop('indeterminate', true);
    }
    else {
      $selectAllBtn.find('#select-all-checkbox').prop({'checked': false, 'indeterminate': false});
    }

    that.updateSelectAllBtnState();
  });

  // Remove default datatable button listener to make the checkbox "checking"
  // work, before adding our own click handler.
  $selectAllBtn.off('click.dtb').click( function (){
    if (that.areAllSelected() || that.areAllSelected({filter: 'applied'})) {
      that.dataTable.rows().deselect();
    }
    else {
      that.dataTable.rows({filter: 'applied'}).select();
    }
  });

  this.dataTable.on('search.dt', function (){
    that.updateSelectAllBtnState();
  });
}


DradisDatatable.prototype.areAllSelected = function(filter = {}) {
  return(
    this.dataTable.rows({selected: true}).count() == this.dataTable.rows(filter).count()
  );
}

DradisDatatable.prototype.updateSelectAllBtnState = function() {
  var $selectAllBtn = $(this.dataTable.buttons('#select-all').nodes()[0]);

  if (this.areAllSelected() || this.areAllSelected({filter: 'applied'})) {
    $selectAllBtn.attr('title', 'Deselect all');
  }
  else {
    $selectAllBtn.attr('title', 'Select all');
  }
}
