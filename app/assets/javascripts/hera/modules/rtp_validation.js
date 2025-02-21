class RTPValidation {
  constructor({ rtpId, template, templateType, uploader }) {
    this.$rtpValidation = $('[data-behavior~=rtp-validation]');
    this.rtpId = rtpId;
    this.template = template;
    this.templateType = templateType;
    this.url = this.$rtpValidation.data('url');
    this.uploader = uploader;

    this.init();
  }

  init() {
    if (!this.url) {
      return;
    }

    var that = this;

    var $resultContainer = that.$rtpValidation.find('[data-behavior~=rtp-validation-result]');
    var $spinner = that.$rtpValidation.find('[data-behavior~=rtp-validation-spinner]');
    var data = {
      report_template_properties_id: that.rtpId,
      template: that.template,
      template_type: that.templateType,
      uploader: that.uploader
    };

    $.ajax({
      url: that.url,
      method: 'post',
      data: data,
      beforeSend: function() {
        $resultContainer.html('');
        $spinner.toggleClass('d-none');
      },
      success: function(data) {
        $resultContainer.html(data);
        $spinner.toggleClass('d-none')
        $(window).trigger('resize'); // check if scroll-for-more indicator is needed.
      }
    })
  }
}
