$(document).on('preInit.dt', function (e, settings) {
  var $paths = $('[data-behavior~=datatable-paths]');
  if ($paths.data('table-state-url') == undefined) {
    return;
  }

  var api = new $.fn.dataTable.Api(settings);

  api.button().add(1, {
    attr: {
      'data-behavior': 'table-action',
    },
    autoClose: true,
    className: 'd-none',
    extend: 'collection',
    name: 'stateBtn',
    text: '<i class="fa-solid fa-adjust fa-fw"></i>State</i>',
    buttons: DradisDatatable.prototype.setupStateButtons.call(api),
  });
});

$(document).on('init.dt', function (e, settings) {
  var $paths = $('[data-behavior~=datatable-paths]');
  if ($paths.data('table-state-url') == undefined) {
    return;
  }

  var api = new $.fn.dataTable.Api(settings);
  api.on(
    'select.dt deselect.dt',
    function () {
      var selectedCount = this.rows({ selected: true }).count();
      DradisDatatable.prototype.toggleStateBtn.call(api, selectedCount !== 0);
    }.bind(api)
  );
});

DradisDatatable.prototype.setupStateButtons = function () {
  var states = $('[data-behavior~=dradis-datatable]').data('state-icons'),
    stateButtons = [],
    api = this;

  states.forEach(function (state) {
    stateButtons.push({
      text: $(
        `<i class="fa-solid ${state[1]} fa-fw me-2"></i><span>${state[0]}</span>`
      ),
      action: DradisDatatable.prototype.updateRecordState.call(
        api,
        state[0].toLowerCase().replaceAll(' ', '_')
      ),
    });
  });

  return stateButtons;
};

DradisDatatable.prototype.updateRecordState = function (newState) {
  var api = this;

  return function () {
    var $paths = $('[data-behavior~=datatable-paths]');
    var selectedRows = this.rows({ selected: true });

    $.ajax({
      url: $paths.data('table-state-url'),
      method: 'PATCH',
      data: {
        ids: DradisDatatable.prototype.rowIds(selectedRows),
        state: newState,
        return_to: $paths.data('table-return-to'),
      },
      success: function () {
        DradisDatatable.prototype.toggleStateBtn.call(api, false);

        selectedRows.deselect().remove().draw();

        $('[data-behavior="qa-alert"]').remove();
        $('.page-title').after(`
          <div class="alert alert-success alert-dismissible" data-behavior="qa-alert">
            <a class="btn-close" data-bs-dismiss="alert" href="javascript:void(0)"><span class="visually-hidden">Close alert</span></a>
            Successfully set the records as ${newState}!
          </div>
        `);
      },
      error: function (xhr, status, msg) {
        console.log('Update state error: ' + msg);
      },
    });
  }.bind(this);
};

DradisDatatable.prototype.toggleStateBtn = function (isShown) {
  var stateBtn = this.buttons('stateBtn:name');
  $(stateBtn[0].node).toggleClass('d-none', !isShown);
};
