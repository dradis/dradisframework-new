class LocalAutoSave {
  constructor(target) {
    if (target.tagName !== 'FORM') { console.error('Can\'t initialize local auto save on anything but a form'); return; }
    this.cancelled = false;
    this.debounceTimer = 500;
    this.key = target.dataset.autoSaveKey;
    this.submitted = false;
    this.target = target;

    // Don't store authenticity_token and utf8
    this.excludedInputNames = ['utf8', 'authenticity_token', '_method'];

    this.init();
  }

  init() {
    this.behaviors();
    this.restoreData();
  }

  behaviors() {
    var that = this;

    this.target.addEventListener('submit', function(event) {
      that.submitted = true;
      localStorage.removeItem(that.key);
    });

    var clearCacheElement = this.target.querySelector('[data-behavior~=clear-local-auto-save]');

    if (clearCacheElement) {
      clearCacheElement.addEventListener('click', function(event) {
        that.cancelled = true;
        localStorage.removeItem(that.key);
      })
    }

    this.target.querySelectorAll('input, textarea, select').forEach(function(input) {
      // Don't add event handler for submit button
      if (input.type === 'button') { return true; }

      // we're using a jQuery plugin for :textchange event, so need to use $()
      $(input).on('textchange change', that.handleTextChange.bind(that));
    })
  }

  handleTextChange() {
    clearTimeout(this.debounceTimeout);

    this.debounceTimeout = setTimeout(function() {
      this.setData();
    }.bind(this), this.debounceTimer);
  }

  getData() {
    var that = this;
    var data = new FormData(this.target);
    var dataArray = Array.from(data).filter(function(dataElement) {
      return !that.excludedInputNames.includes(dataElement[0] );
    });

    return dataArray;
  }

  restoreData() {
    var that = this;
    var data = JSON.parse(localStorage.getItem(this.key));

    if (data !== null) {
      // Deserialization of form data
      // Reference: https://wildwolf.name/store-formdata-object-in-localstorage/
      for (var item of data) {
        var name = item[0];
        var element = that.target.elements[name];

        // Skip loop if element is undefined
        if (!element) { continue; }

        // RadioNodeList is an array of checkboxes or radio buttons
        if (element instanceof RadioNodeList) {
          element.forEach(function(radioNodeListElement) {
            if (['checkbox', 'radio'].includes(radioNodeListElement.type)) {
              if (radioNodeListElement.value === item[1]) {
                radioNodeListElement.checked = true;
              }
            }
          })
        } else if (element.type === 'checkbox') {
          if (element.value === item[1]) {
            element.checked = true;
          }
        } else if (element.type === 'file') {
          element.value = '';
        } else if (element.name === 'issue[tag_list]') {
          var $tagDropdownItem = $(`.js-taglink[data-tag='${item[1]}']`);
          new SelectTagDropdown($tagDropdownItem)
        } else {
          element.value = item[1];
        }

        $(element).trigger('load-preview');
      }
    }
  }

  setData() {
    if (!this.cancelled && !this.submitted) {
      localStorage.setItem(this.key, JSON.stringify(this.getData()));
    } else {
      // Reset the submit state, needed for comment form
      this.submitted = false;
    }
  }
}
