(function ($, window) {
  function Sidebar($sidebar) {
    this.$sidebar = $sidebar;
    this.minBreakpoint = 992;
    this.$navbarBrand = $sidebar
      .siblings('[data-behavior~=navbar]')
      .find('[data-behavior~=navbar-brand]');
    this.$nodeTree = $sidebar.find($('[data-behavior~=node-tree-content]'));
    this.$nodeTreeToggle = $sidebar.find(
      $('[data-behavior~=toggle-node-tree]')
    );
    this.storageKey = $sidebar.data('storage-key');
    this.$toggleLink = $sidebar.find($('[data-behavior~=sidebar-toggle]'));
    this.$viewContent = $sidebar.siblings('[data-behavior~=view-content]');

    this.init();
  }

  Sidebar.prototype = {
    init: function () {
      this.toggle(this.isSidebarOpen());
      this.toggleNodeTree(this.isNodeTreeOpen());

      var that = this;

      this.$toggleLink.on('click', function () {
        if ($(this).is('[data-behavior~=nodes-tree]')) {
          if (window.innerWidth < that.minBreakpoint) {
            $(this).attr('data-behavior', 'nodes-tree sidebar-toggle');
          } else {
            $(this).attr(
              'data-behavior',
              'nodes-tree sidebar-toggle open-only'
            );
            that.nodeTreeOpen();
          }
        }

        if (
          !(that.isSidebarOpen() && $(this).is('[data-behavior~=open-only]'))
        ) {
          that.toggle(!that.isSidebarOpen());
        }
      });

      this.$nodeTreeToggle.on('click', function (e) {
        e.stopPropagation();
        that.toggleNodeTree(!that.isNodeTreeOpen());
      });

      if (window.innerWidth < that.minBreakpoint) {
        $('[data-behavior~=sidebar-node-link]').on('click', function () {
          that.close();
        });
      }

      $(window).on('resize', function () {
        if (window.innerWidth < that.minBreakpoint) {
          that.$navbarBrand.css('padding-left', 0);
        }

        that.isSidebarOpen() ? that.open() : that.close();
      });
    },
    changeState: function (key, state) {
      localStorage.setItem(key, state);
      Turbo.cache.clear();
    },
    close: function () {
      this.$sidebar
        .removeClass('sidebar-expanded')
        .addClass('sidebar-collapsed');

      if (this.$sidebar.is($('[data-behavior~=main-sidebar]'))) {
        this.$navbarBrand.css('padding-left', 0);
        this.$viewContent.css({
          left: this.$sidebar.css('width'),
          width: `calc(100vw - ${this.$sidebar.css('width')})`,
        });
      }

      this.changeState(this.storageKey, false);
    },
    isNodeTreeOpen: function () {
      if (JSON.parse(localStorage.getItem('node-tree-expanded')) === null) {
        return true;
      } else {
        return JSON.parse(localStorage.getItem('node-tree-expanded'));
      }
    },
    isSidebarOpen: function () {
      if (JSON.parse(localStorage.getItem(this.storageKey)) === null) {
        return true;
      } else {
        return JSON.parse(localStorage.getItem(this.storageKey));
      }
    },
    open: function () {
      this.$sidebar
        .removeClass('sidebar-collapsed')
        .addClass('sidebar-expanded');

      if (this.$sidebar.is($('[data-behavior~=main-sidebar]'))) {
        this.$viewContent.css({
          left: this.$sidebar.css('width'),
          width: `calc(100vw - ${this.$sidebar.css('width')})`,
        });

        if (window.innerWidth > this.minBreakpoint) {
          var navbarBrandOffset = parseFloat(
            this.$sidebar.css('width').slice(0, -2) / 1.65
          );
          this.$navbarBrand.css('padding-left', navbarBrandOffset);
        }
      }

      this.changeState(this.storageKey, true);
    },
    nodeTreeClose: function () {
      this.$nodeTree.removeClass('show');
      this.$nodeTreeToggle
        .find($('[data-behavior~=toggle-icon]'))
        .removeClass('fa-chevron-up')
        .addClass('fa-chevron-down');
      this.$nodeTree.on(
        'hidden.bs.collapse',
        this.changeState('node-tree-expanded', false)
      );
    },
    nodeTreeOpen: function () {
      this.$nodeTree.addClass('show');
      this.$nodeTreeToggle
        .find($('[data-behavior~=toggle-icon]'))
        .removeClass('fa-chevron-down')
        .addClass('fa-chevron-up');
      this.$nodeTree.on(
        'shown.bs.collapse',
        this.changeState('node-tree-expanded', true)
      );
    },
    toggleNodeTree: function (openNodeTree) {
      openNodeTree ? this.nodeTreeOpen() : this.nodeTreeClose();
    },
    toggle: function (openSidebar) {
      openSidebar ? this.open() : this.close();
    },
  };

  window.Sidebar = Sidebar;
})(jQuery, window);
