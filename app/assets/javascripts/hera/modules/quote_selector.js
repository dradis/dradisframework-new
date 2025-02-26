/*

To initialize:

new QuoteSelector(EditorToolbar);

Where `content` is an element of [data-behavior=content-textile]
*/

class QuoteSelector {
  constructor(content) {
    this.$content = $(content);

    // Only ever assign a single quote selector to a container
    if (this.$content.data('quoteSelector') !== undefined) {
      return;
    }

    // Only assign a quote selector if we have a rich text editor to quote too
    if ($('[data-behavior~=rich-toolbar]').length === 0) {
      return;
    }

    this.init();
  }

  init() {
    this.$quoteBtn = $(
      '\
      <div class="selection-quote-button d-none" data-behavior="selection-quote-button" aria-label="quote text">\
          <i class="fa-solid fa-quote-left fa-fw me-1"></i>\
          <span>Quote Text</span>\
      </div>'
    );

    // Append the quote button to the comments feed on load
    this.appendQuoteBtn();

    // Async liquid render replaces the content, including the quote button, so
    // we append the quote button to record's content after rendering liquid.
    this.$content.on('dradis:liquid-rendered', () => {
      this.appendQuoteBtn();
    });
  }

  appendQuoteBtn() {
    this.$content.append(this.$quoteBtn);
    this.$content.data('quoteSelector', this);
    this.behaviors();
  }

  behaviors() {
    var that = this;

    // Use the only editor we can find if there's only one.
    window.lastActiveEditor = $('[data-behavior~=rich-toolbar]:visible').data(
      'editorToolbar'
    );

    // Get the selected text positions so we can place the quote box above it
    $(document).on('mouseup', function () {
      var selectionObj = document.getSelection(),
        quoteableSelector = '[data-behavior~=content-textile]';

      if (isValidSelection(selectionObj, quoteableSelector)) {
        var selectionPosition = selectionObj
            .getRangeAt(0)
            .getBoundingClientRect(),
          parentPosition = that.$content[0].getBoundingClientRect(),
          boundingBoxY = selectionPosition.y - parentPosition.y,
          chevronOffsetY = 8, // Psuedo element downward chevron under quote button
          chevronOffsetX = 15, // Psuedo element downward chevron left offset from button left side
          clonedRange = selectionObj.getRangeAt(0).cloneRange();

        // Clone the range and collapse it so we can take measurement of only
        // the first line. We make a clone because calling `collapse` will
        // unselect the content the user has highlighted if we call it on the
        // original element.
        clonedRange.collapse(true);
        var boundingBoxX =
          clonedRange.getBoundingClientRect().x - parentPosition.x;

        that.$quoteBtn.removeClass('d-none').css({
          top: boundingBoxY - (that.$quoteBtn.outerHeight() + chevronOffsetY),
          left: boundingBoxX - chevronOffsetX,
        });
      }

      // Only show a quote button if:
      //  - there is a selection
      //  - the selection starts and ends within a content-textile container
      //  - show the quote button for only the selection container
      function isValidSelection(obj, selector) {
        if (
          !obj.isCollapsed &&
          $(obj.anchorNode).parents(selector).length == 1 &&
          $(obj.focusNode).parents(selector).length == 1 &&
          $(obj.anchorNode).parents(selector).is(that.$content)
        ) {
          return true;
        } else {
          return false;
        }
      }
    });

    // Clear the quote box and selection
    $(document).on('mousedown', function (e) {
      if (
        !$(e.target).parent().is('[data-behavior~=selection-quote-button]') &&
        !e.shiftKey
      ) {
        that.clear();
      }
    });

    this.$quoteBtn.on('click', function () {
      var selectionText = document.getSelection().toString(),
        affix,
        editor;

      if (window.lastActiveEditor.$editorField.is('visible')) {
        editor = window.lastActiveEditor;
      } else {
        editor = $('[data-behavior~=rich-toolbar]:visible').data(
          'editorToolbar'
        );
      }

      affix = editor.affixesLibrary('quote', selectionText);
      editor.injectSyntax(affix);

      that.clear();
    });
  }

  clear() {
    this.$quoteBtn.addClass('d-none');

    if (document.getSelection().empty) {
      // Chrome
      document.getSelection().empty();
    } else if (document.getSelection().removeAllRanges) {
      // Firefox
      document.getSelection().removeAllRanges();
    }
  }
}
