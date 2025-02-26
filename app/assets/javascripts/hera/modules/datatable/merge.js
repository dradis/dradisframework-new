DradisDatatable.prototype.setupMergeButtonToggle = function() {
  if (this.$paths.data('table-merge-url') === undefined) {
    return;
  }

  this.dataTable.on('select.dt deselect.dt', function() {
    var isHidden = this.dataTable.rows({selected:true}).count() < 2;
    var mergeBtn = this.dataTable.buttons('mergeBtn:name')[0].node;
    $(mergeBtn).toggleClass('d-none', isHidden);
  }.bind(this));
}

DradisDatatable.prototype.mergeSelected = function() {
  var url = this.$paths.data('table-merge-url');

  if (url !== undefined) {
    location.href = url + '?ids=' + this.rowIds(this.dataTable.rows({selected: true}));
  }
}
