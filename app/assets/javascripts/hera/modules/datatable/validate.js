DradisDatatable.prototype.setupValidation = function() {
  if (this.$paths.data('table-validate-url') == undefined) {
    return;
  }

  this.setupValidationListeners();
  this.validateRecords();
}

DradisDatatable.prototype.setupValidationListeners = function() {
  // Subscribe to ValidationsChannel
  this.$table.trigger('dradis:datatable:validation');

  var that = this;

  this.dataTable.on('column-visibility.dt', function (e, settings, columnIndex, visible) {
    if (that.validationColumnIndex() == columnIndex && visible && !that.hasValidationTriggered()) {
      that.validateRecords();
    }
  });
}

DradisDatatable.prototype.validateRecords = function() {
  if (!this.isValidationColumnVisible()) {
    return;
  }

  this.$table.data('validation-triggered', true);

  var itemName = this.itemName;
  var itemsToValidate = [];

  if (itemName !== undefined) {
    var capitalizedItemType = itemName[0].toUpperCase() + itemName.slice(1);

    itemsToValidate = this.rowIds(this.dataTable.rows());

    if (itemsToValidate.length > 0) {
      $.ajax({
        url: this.$paths.data('table-validate-url'),
        method: 'POST',
        dataType: 'script',
        data: { ids: itemsToValidate, resource_type: capitalizedItemType },
        beforeSend: function() {
          $('[data-behavior~=validate-column]').addClass('loading');
        },
        success: function() {
          $('[data-behavior~=validate-column]').removeClass('loading');
        }
      });
    }
  }
}

DradisDatatable.prototype.hasValidationTriggered = function() {
  return this.$table.data('validation-triggered');
}

DradisDatatable.prototype.isValidationColumnVisible = function() {
  return this.dataTable.column(this.validationColumnIndex()).visible();
}

DradisDatatable.prototype.validationColumnIndex = function() {
  return this.tableHeaders.findIndex(function(th) {
    return th.dataset.column == 'validation';
  });
}
