// Textile editor plugin with Write/Preview/Fullscreen functionality
//
// References:
//   jQuery boilerplate - http://jqueryboilerplate.com/
//   Inspired in redactor.js - http://redactorjs.com/

// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ( $, window, undefined ) {

  // undefined is used here as the undefined global variable in ECMAScript 3 is
  // mutable (ie. it can be changed by someone else). undefined isn't really being
  // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
  // can no longer be modified.

  // window and document are passed through as local variables rather than globals
  // as this (slightly) quickens the resolution process and can be more efficiently
  // minified (especially when both are regularly referenced in your plugin).

  // Create the defaults once
  var pluginName = 'textile',
      document = window.document,
      defaults = {
        defaultViewKey: 'editor.view',
        // Start fullscreen?
        fullscreen: false,
        // Add a resizer bar at the bottom of the editor
        resize: true,
        // HTML templates
        tpl: {
          fields: '<div class="textile-form h-100 col-12 col-lg-6"></div>',
          wrap: '<div class="textile-wrap" data-behavior="textile-wrap"><ul class="textile-toolbar"></ul><div class="textile-inner row"></div></div>',
          preview: '<div class="col-12 col-lg-6"><div class="textile-preview loading-indicator">Loading...</div></div>',
          help: '<div class="textile-help col-12 loading-indicator">Loading...</div>'
        }
      };

  // The actual plugin constructor
  function Plugin( element, options ) {
    this.$element = $(element);

    // jQuery has an extend method which merges the contents of two or
    // more objects, storing the result in the first object. The first object
    // is generally empty as we don't want to alter the default options for
    // future instances of the plugin
    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name = pluginName;

    this.init();
  }

  Plugin.prototype = {
    init: function () {
      // Place initialization logic here
      // You already have access to the DOM element and the options via the instance,
      // e.g., this.element and this.options
      this._buildContainer();

      this._previousContent = this.$element.val();
      this._previewRendered = false;
      this._helpRendered = false;
      this._doneTypingInterval = 500;
    },
    _buildContainer: function() {
      // Add wrapper div with toolbar and inner container (see defaults.tpl)

      // container
      this.options.$wrap = $(this.options.tpl.wrap);
      this.$element.parent().append( this.options.$wrap );

      // move textarea to container
      this.$source = this.$element.wrap('<div class="col-12 col-lg-6"></div>').parent();
      $('.textile-inner', this.options.$wrap).append(this.$source);
      this.$source.hide();

      // add Form
      this.options.$fields = $(this.options.tpl.fields);
      $('.textile-inner', this.options.$wrap).append(this.options.$fields);
      this._loadFields(this.$element.val(), this.$element.data('allow-dropdown'));

      // add Preview to container and load
      this.options.$preview = $(this.options.tpl.preview);
      $('.textile-inner', this.options.$wrap).append(this.options.$preview);
      this.options.$preview.children(':first').addClass('textile-preview');
      this._loadPreview({ text: this.$element.val() });

      // add Help to container and hide
      this.options.$help = $(this.options.tpl.help);
      $('.textile-inner', this.options.$wrap).append(this.options.$help);
      this.options.$help.hide();

      // toolbar
      this._buildToolbar();

      // Event bindings
      this._bindBehaviors();

      this._setDefaultView();
    },
    _bindBehaviors: function() {
      // Sync preview
      // on keyup, start the countdown
      this.$element.on('textchange load-preview', function() {
        clearTimeout(this._typingTimer);
        this._typingTimer = setTimeout(this._onKeyPressPreview.bind(this, 'text'), this._doneTypingInterval);
      }.bind(this));

      // When auto-save populates data into source view refresh the form
      this.$element.on('load-preview', function() {
        this._loadFields(this.$element.val());
      }.bind(this));

      // Bind all form element actions within container
      this.bindFieldGroup(this.options.$fields);
    },
    bindFieldGroup: function($parent) {
      var that = this;

      $parent.find('[data-behavior~=delete-field]').click(function(){
        $(this).closest('[data-behavior~=textile-form-field]').remove();
        that._timedPreview.bind(that)();
      });

      $parent.find('[data-behavior~=edit-field]').click(function(){
        $parent.find($(this).data('edit-field')).focus();
      });

      // Handler for triggering the preview on keyboard input
      $parent.find('[data-behavior~=preview-enabled]').on('textchange load-preview', this._timedPreview.bind(this));
    },
    _timedPreview: function(view) {
      clearTimeout(this._typingTimer);
      this._typingTimer = setTimeout(function() {
        this._onKeyPressPreview.bind(this, view)

        // Piggy back this event for the purpose of updating the source view, which will trigger auto-save
        // This will be updated/refactored when auto-save is re-worked. Currently it will cause an extra request per edit.
        this._loadSource();
        this.$element.trigger('textchange');
      }.bind(this), this._doneTypingInterval);
    },
    _buildToolbar: function() {
      var button;

      // Form
      button = $('<a class="btn-form active" href="javascript:void(null);"><span>Fields</span></a>');
      button.click( $.proxy( function(evt) { this._onBtnFields(evt); }, this));
      $('.textile-toolbar', this.options.$wrap).append( $('<li>').append(button) );

      // Source
      button = $('<a class="btn-write" href="javascript:void(null);"><span>Source</span></a>');
      button.click( $.proxy( function(evt) { this._onBtnSource(evt); }, this));
      $('.textile-toolbar', this.options.$wrap).append( $('<li>').append(button) );

      // Full screen
      // button = $('<a class="btn btn-fullscreen" href="javascript:void(null);"><span>&nbsp;</span></a>');
      button = $('<a class="btn-fullscreen fa fa-expand" href="javascript:void(null);"><span>&nbsp;</span><span class="sr-only">Toggle Fullscreen</span></a>');
      button.click( $.proxy( function(evt) { this._onBtnFullScreen(evt); }, this));
      $('.textile-toolbar', this.options.$wrap).append( $('<li class="right">').append(button) );

      // Help
      button = $('<a class="btn-help fa fa-question" href="javascript:void(null);"><span>&nbsp;</span><span class="sr-only">Toggle Help</span></a>');
      button.click( $.proxy( function(evt) { this._onBtnHelp(evt); }, this));
      $('.textile-toolbar', this.options.$wrap).append( $('<li class="right">').append(button) );
    },
    _buildResizer: function() {
      if (this.options.resize === false) return false;

    },

    _contentHasFields: function() {
      // Match the first instance of a field header.
      var regex = /#\[.+?\]#/;

      // Returns an array of matches (truthy) or null (falsey) if there's no match.
      return this.$element.val().match(regex);
    },

    // Ajax form
    _loadFields: function(data, allowDropdown) {
      $.post({
        url: this.$element.data('paths').form_url,
        data: {source: data, allow_dropdown: allowDropdown},
        beforeSend: function(){
          this.options.$fields.addClass('loading-indicator').text('Loading...');
        }.bind(this),
        success: function(result) {
          this.options.$fields.removeClass('loading-indicator')
            .html(result);
          this.bindFieldGroup(this.options.$fields);
          this.options.$fields.trigger('textile:formLoaded');
        }.bind(this)
      });
    },
    // Ajax help
    _loadHelp: function() {
      var that = this;
      $.get( this.$element.data('paths').help_url, function(result){
        that.options.$help.removeClass('loading-indicator')
          .html(result);
        this._helpRendered = true;
      });
    },
    // Ajax preview
    _loadPreview: function(data) {
      this._previousContent = this.$element.val();

      $.post({
        url: this.$element.data('paths').preview_url,
        data: JSON.stringify(data),
        dataType: 'html',
        contentType: 'application/json',
        success: function(result) {
          this.options.$preview.removeClass('loading-indicator').html(result);
          if (result == '\n') {
            this.options.$preview.append('<div class="preview-placeholder"><h5>Add some fields to see a live preview here</h5></div>')
          }
          this.options.$preview.children(':first').addClass('textile-preview');
          this._previewRendered = true;
        }.bind(this),
        error: function() {
          this._showTimeoutMessage();
        }.bind(this)
      });
    },
    // Ajax write
    _loadSource: function() {
      $.post({
        url: this.$element.data('paths').source_url,
        data: JSON.stringify({ form: this._serializedFormData() }),
        contentType: 'application/json',
        success: function(result){
          this.$element.val(result);
        }.bind(this),
        error: function() {
          this._showTimeoutMessage();
        }.bind(this)
      });
    },
    _onKeyPressPreview: function(type) {
      if (type == 'fields') {
        this._loadPreview({ fields: this._serializedFormData() });
      }
      else if (type == 'text') {
        // If the text hasn't changed, do nothing.
        if (this._previousContent == this.$element.val()) {
          if (!this._previewRendered) {
            this._loadPreview({ text: this.$element.val() });
          }
        } else {
          this._loadPreview({ text: this.$element.val() });
        }
      }
    },
    _onBtnFields: function() {
      localStorage.setItem(this.options.defaultViewKey, 'fields');
      // Activate toolbar button
      var scope = this.options.$wrap;
      $('.textile-toolbar a', scope).removeClass('active');
      $('.textile-toolbar .btn-form', scope).addClass('active');

      $('.textile-form').empty();

      this._loadFields(this.$element.val(), false);

      // Show Form pane
      this.options.$help.hide();
      this.$source.hide();
      this.options.$preview.show();
      this.options.$fields.show();
    },
    _onBtnFullScreen: function() {
      $btnFS = $('.btn-fullscreen', this.options.$wrap);

      if (this.options.fullscreen === false ) {
        this.options.fullscreen = true;

        this.options.$wrap.addClass('textile-fullscreen');
        this.options.$wrap.attr('data-behavior', 'textile-wrap textile-fullscreen');

        $('[data-behavior~=view-content]').css('z-index', 5);

        // update button icon
        $btnFS.removeClass('fa-expand').addClass('fa-compress');

        // back to top for good measure
        $(document).scrollTop(0,0);
      }
      else
      {
        this.options.fullscreen = false;

        this.options.$wrap.removeClass('textile-fullscreen').attr('data-behavior', 'textile-wrap');

        $('[data-behavior~=view-content]').css('z-index', 'auto');

        // update button icon
        $btnFS.removeClass('fa-compress').addClass('fa-expand');
      }
    },
    _onBtnHelp: function() {
      var scope = this.options.$wrap;
      $('.textile-toolbar a', scope).removeClass('active');
      $('.textile-toolbar .btn-help', scope).addClass('active');

      // Show Help pane
      this.$source.hide();
      this.options.$fields.hide();
      this.options.$preview.hide();
      this.options.$help.show();

      if (!this._helpRendered) {
        this._loadHelp();
      }
    },
    // Toolbar button handlers
    _onBtnSource: function() {
      localStorage.setItem(this.options.defaultViewKey, 'source');
      // Activate toolbar button
      var scope = this.options.$wrap;
      $('.textile-toolbar a', scope).removeClass('active');
      $('.textile-toolbar .btn-write', scope).addClass('active');

      // Clear out the form
      this.options.$fields.empty();

      // Show Source pane
      this.options.$fields.hide();
      this.options.$help.hide();
      this.options.$preview.show();
      this.$source.show();
      this.$source.find('textarea').focus();
    },

    // --------------------------------------------------- Other event handlers

    _serializedFormData: function() {
      return $('[name^=item_form]', this.options.$fields).serializeArray();
    },

    _setDefaultView: function() {
      if (localStorage.getItem(this.options.defaultViewKey) == 'source' || !this._contentHasFields) {
        this._onBtnSource();
      }
    },

    _showTimeoutMessage: function() {
      var that = this;
      that.options.$preview.parent().find('.alert').remove();
      that.options.$preview.prepend('<p class="alert alert-danger">Your session has expired!. Login again to continue.</p>');
      $('[data-behavior~=textile-wrap]').animate({
        scrollTop: that.options.$preview.scrollTop()
      });
    }
  };

  // A really lightweight plugin wrapper around the constructor,
  // preventing against multiple instantiations
  $.fn[pluginName] = function ( options ) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin( this, options ));
      }
    });
  };
}(jQuery, window));
