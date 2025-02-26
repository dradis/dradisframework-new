$(document).on('preInit.dt', function (e, settings) {
  var $paths = $('[data-behavior~=datatable-paths]');
  if ($paths.data('table-state-url') == undefined) {
    return;
  }

  var api = new $.fn.dataTable.Api(settings);

  api.button().add(1, {
    attr: {
      'data-behavior': 'table-action datatable-state-button',
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

  $('[data-behavior~=datatable-state-button]').click(
    DradisDatatable.prototype.reenableTooltip
  )
});

DradisDatatable.prototype.setupStateButtons = function () {
  var states = $('[data-behavior~=dradis-datatable]').data('state-icons'),
    stateButtons = [],
    api = this;

  states.forEach(function (state) {
    const publishDisabled =
      state[0] === 'Published' &&
      !$('[data-can-publish]').data('can-publish');

    let attrs;

    if (publishDisabled) {
      attrs = {
        'data-bs-toggle': 'tooltip',
        'data-bs-title': 'You are not a Reviewer for this project.',
      };
    }

    stateButtons.push({
      action: DradisDatatable.prototype.updateRecordState.call(
        api,
        state[0].toLowerCase().replaceAll(' ', '_'),
        $('[data-can-publish]').data('can-publish')
      ),
      attr: attrs,
      className: publishDisabled ? 'disabled' : null,
      text: $(
        `<i class="fa-solid ${state[1]} fa-fw me-2"></i><span>${state[0]}</span>`
      ),
    });
  });

  return stateButtons;
};

DradisDatatable.prototype.updateRecordState = function (newState, canPublish) {
  if (newState == 'Published' && canPublish) {
    return;
  }

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

DradisDatatable.prototype.reenableTooltip = function (e) {
  var button = $(this).siblings('.dt-button-collection:first').find('.dt-button.disabled');

  if (button.length) {
    window.initBehaviors(button.html());
  }
};
