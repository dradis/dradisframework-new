class DradisDatatable {
  constructor(tableElement) {
    this.$table = $(tableElement);
    this.$paths = this.$table.closest('[data-behavior~=datatable-paths]');

    this.dataTable = null;
    this.itemName = this.$table.data('item-name');
    this.localStorageKey = this.$table.data('local-storage-key');
    this.tableHeaders = Array.from(this.$table[0].querySelectorAll('thead th'));

    var defaultColumns = this.$table.data('default-columns') || [];
    this.defaultColumns = defaultColumns.concat(['Select', 'Actions']);

    this.init();
  }

  init() {
    var that = this;

    // Disable ability to toggle column visibility that has data-column-visible="false"
    var columnVisibleIndexes = [];
    this.tableHeaders.forEach(function (column, index) {
      if (column.dataset.columnVisible != 'false') {
        columnVisibleIndexes.push(index);
      }
    });

    // Only show default columns on first load
    var hiddenColumnIndexes = [];
    if (localStorage.getItem(this.localStorageKey) === null) {
      this.tableHeaders.forEach(function (column, index) {
        var columnName = column.textContent.trim();

        if (!that.defaultColumns.includes(columnName)) {
          hiddenColumnIndexes.push(index);
        }
      });
    }

    // Assign the instantiated DataTable as a DradisDatatable property
    this.dataTable = this.$table.DataTable({
      autoWidth: false,
      buttons: {
        dom: {
          button: {
            tag: 'button',
            className: 'btn',
          },
        },
        buttons: [
          {
            available: function () {
              return that.$table.find('[data-behavior~=select-checkbox]')
                .length;
            },
            attr: {
              id: 'select-all',
            },
            name: 'selectAll',
            text: '<label for="select-all-checkbox" class="visually-hidden">Select all"</label><input type="checkbox" id="select-all-checkbox" />',
            titleAttr: 'Select all',
          },
          {
            attr: {
              'data-behavior': 'table-action',
            },
            text: '<i class="fa-solid fa-trash fa-fw"></i>Delete',
            className: 'text-danger d-none',
            name: 'bulkDeleteBtn',
            action: this.bulkDelete.bind(this),
          },
          {
            attr: {
              'data-behavior': 'table-action',
            },
            available: function () {
              return that.$paths.data('table-merge-url') !== undefined;
            },
            text: '<i class="fa-solid fa-compress fa-fw"></i> Merge',
            name: 'mergeBtn',
            className: 'd-none',
            action: this.mergeSelected.bind(this),
          },
          {
            attr: {
              'data-behavior': 'table-action',
            },
            autoClose: true,
            available: function () {
              return that.$table.data('tags') !== undefined;
            },
            className: 'd-none tag-btn',
            extend: 'collection',
            name: 'tagBtn',
            text: '<i class="fa-solid fa-tags fa-fw"></i>Tag</i>',
            buttons: this.setupTagButtons(),
          },
          {
            extend: 'colvis',
            text: '<i class="fa-solid fa-columns me-1 fa-fw"></i>Columns</i>',
            titleAttr: 'Choose columns to show',
            className: 'btn',
            columns: columnVisibleIndexes,
          },
        ],
      },
      columnDefs: [
        {
          targets: hiddenColumnIndexes,
          visible: false,
        },
      ],
      dom:
        "<'row'<'col-sm-6'B>\
        <'col-sm-6'f>>" +
        "<'row'<'col-lg-12'tr>>" +
        "<'dataTables_footer_content'lip>",
      initComplete: function (settings) {
        settings.oInstance.wrap("<div class='table-wrapper'></div>");
      },
      lengthMenu: [
        [25, 50, 100, -1],
        ['25', '50', '100', 'All'],
      ],
      pageLength: 25,
      stateSave: true,
      stateDuration: 0, // https://datatables.net/reference/option/stateDuration#Default
      // https://datatables.net/reference/option/stateSaveCallback
      // DataTables will call stateSaveCallback() whenever a state change event
      // happens (paging, searching, sorting, showing/hiding columns, etc).
      //
      // This function stores the current state of the DataTable in localStorage.
      //
      // This function is also called immediately after stateLoadCallback() on
      // page load.
      //
      // Example data:
      // {
      //   "time": 1636113289042,
      //   "start": 0,
      //   "length": 25,
      //   "order": [
      //     [
      //       0,
      //       "asc"
      //     ]
      //   ],
      //   "search": {
      //     "search": "sasd",
      //     "smart": true,
      //     "regex": false,
      //     "caseInsensitive": true
      //   },
      //   "columns": [
      //     // Column 1
      //     {
      //       "visible": false,
      //       "search": {
      //         "search": "",
      //         "smart": true,
      //         "regex": false,
      //         "caseInsensitive": true
      //       }
      //     },
      //     // Column 2
      //     {
      //       "visible": true,
      //       "search": {
      //         "search": "",
      //         "smart": true,
      //         "regex": false,
      //         "caseInsensitive": true
      //       }
      //     }
      //   ]
      // }
      stateSaveCallback: function (_settings, savedStateData) {
        var newSavedStateData =
          that.addTableHeadersToSavedStateData(savedStateData);
        localStorage.setItem(
          that.localStorageKey,
          JSON.stringify(newSavedStateData)
        );
      },
      // https://datatables.net/reference/option/stateLoadCallback
      // DataTables will call stateLoadCallback() on page load.
      //
      // It restores the DataTable's previously saved state (think sort state, paginated state,
      // search term, column visibility state, etc) that is stored in localStorage as an object
      // (see stateSaveCallback for example data).
      //
      // This function then returns the saved state object and DataTables will then use the it
      // to display sort state, paginated state, search term, column visibility state, etc, accordingly.
      //
      // If there's no saved state, this function must return null.
      //
      // If the length of columns array (from the saved state, see above for example)
      // doesn't match the number of columns that was initialized with DataTable (from the page),
      // DataTable will reset it, causing the previously saved state to be gone.
      //
      // This scenario happens when columns are added or removed from the table but
      // did not trigger stateSaveCallback().
      //
      // Example scenario:
      // After a new field is added to an issue, the new field will show up as a column in issues#index.
      // But this new column's state isn't present in the saved state object,
      // causing it to reset everything.
      //
      // To prevent a reset from happening, we just have to ensure that the number of columns on the page
      // matches the length of columns array in the saved state object.
      stateLoadCallback: function (_settings) {
        var localStorageData = JSON.parse(
          localStorage.getItem(that.localStorageKey)
        );

        if (localStorageData !== null) {
          return that.rebuildSavedStateColumnsFromLocalStorage(
            localStorageData
          );
        } else {
          return null;
        }
      },
      select: {
        selector: 'td.select-checkbox',
        style: 'multi',
      },
    });

    this.behaviors();
  }

  behaviors() {
    this.setupCheckboxListeners();
    this.setupMergeButtonToggle();
    this.setupTagButtonToggle();
    this.setupBulkDeleteButtonToggle();
    this.setupValidation();

    this.$table.trigger('dradis:datatable:load');

    this.unbindDataTable();
  }

  // DataTable uses indexes in the columns array (from saved state) to figure out the state of the column.
  // We cannot reliably know from the saved state object which index in the saved state's columns array
  // came from which table column on the page, so we add the table's column header
  // in the data before saving it in localStorage.
  addTableHeadersToSavedStateData(data) {
    this.tableHeaders.forEach(function (th, index) {
      data.columns[index].header = th.textContent;
    });

    return data;
  }

  toggleLoadingState(rows, isLoading) {
    var buttons = this.dataTable
      .buttons('[data-behavior~=table-action]')
      .nodes();

    $(buttons).toggleClass('disabled', isLoading);

    rows
      .nodes()
      .toArray()
      .forEach(function (tr) {
        if (isLoading) {
          $(tr).find('[data-behavior~=error-loading]').remove();
          $(tr)
            .find('[data-behavior~=select-checkbox]')
            .append(
              '<div class="spinner-border spinner-border-sm text-primary" data-behavior="spinner"><span class="visually-hidden">Loading</div>'
            );
        } else {
          $(tr).find('[data-behavior~=spinner]').remove();
        }
      });
  }

  rowIds(rows) {
    var ids = rows
      .ids()
      .toArray()
      .map(function (id) {
        // The dom id for <tr> is in the following format: <tr id="item_name-id"></tr>,
        // so we split it by the delimiter to get the id number.
        return id.split('-')[1];
      });
    return ids;
  }

  unbindDataTable() {
    var that = this;

    document.addEventListener('turbolinks:before-cache', function () {
      that.dataTable.destroy();
    });
  }

  // As we already added table headers in the saved state object before saving it in
  // localStorage (see addTableHeadersToSavedStateData()), we can use it to
  // identify if a column (on the page) is new, existing or removed.
  //
  // If a table column is a new column, its header will not be present in the saved state
  // object, so we assign a blank state to the column state with default visibility = false.
  //
  // If a table column is an existing column, its header will be present in the saved state
  // object, so we return the existing column state.

  // Old columns are automatically removed, because we are iterating the columns
  // on the page, and not columns inside the saved state object.
  rebuildSavedStateColumnsFromLocalStorage(localStorageData) {
    var containsHeader = localStorageData.columns.some(function (column) {
      return 'header' in column;
    });

    // Return localStorageData if none of the columns contain the header property,
    // so that we don't show a page without columns.
    if (!containsHeader) {
      return localStorageData;
    }

    var newColumns = [];

    this.tableHeaders.forEach(function (th, _index) {
      var columnData = { visible: false };

      var column = localStorageData.columns.find(function (column) {
        if (column.header == th.textContent) {
          columnData = column;
          return true;
        }
      });

      newColumns.push(columnData);
    });

    localStorageData.columns = newColumns;
    return localStorageData;
  }
}
