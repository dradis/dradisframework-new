class Differ {
  constructor() {
    this.delRegex = /\[31m([\s\S]*?)\[0m/g;
    this.insRegex = /\[32m([\s\S]*?)\[0m/g;
  }

  ansiToHTML(text) {
    return text
      .replace(this.delRegex, '<del class="differ">$1</del>')
      .replace(this.insRegex, '<ins class="differ">$1</ins>');
  }

  highlightString(text, diffType) {
    if (diffType === 'del') {
      return text
        .replace(this.delRegex, '<mark>$1</mark>')
        .replace(this.insRegex, '');
    }
    else if (diffType === 'ins') {
      return text
        .replace(this.insRegex, '<mark>$1</mark>')
        .replace(this.delRegex, '');
    }
    else {
      console.log('Invalid diffType!');
    }
  }
}

document.addEventListener('turbolinks:load', function() {
  if ($('.js-diff-body').length) {
    let differ = new Differ(),
        content = $('.js-diff-body').html();

    $('.js-diff-body').html(differ.ansiToHTML(content));
  }
});
