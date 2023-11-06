document.addEventListener('turbo:load', function() {
  if ($('body.unauthenticated').length) {
    var charCount = 0,
        strings = setStrings(),
        randomStringIndex = Math.floor(Math.random() * strings.length),
        randomString = strings[randomStringIndex];

    function setStrings() {
      if ($('body.unauthenticated').hasClass('holiday')) {
        return [
          'Yippie Ki Yay!',
          'Follow the white rabbit',
          'Take the red pill',
          'There is no spoon',
          'Eat, sleep, hack, repeat',
          'I am Jack\'s complete lack of surprise',
          'Greetings Professor Falken',
          'There is no right and wrong. There\'s only fun and boring.',
          'The cake is a lie'
        ]
      } else {
        return [
          'The same reports, in a fraction of the time',
          'Deliver consistent results, every time',
          'Combine output from multiple tools easily',
          'Spend less time reporting and more time testing',
          'The entire team knows how the project is going',
          'Working better, together'
        ]
      }
    }

    setTimeout(function() {
      setInterval(function() {
        if (charCount <= randomString.length) {
          $('[data-behavior~=mission-text]').text(randomString.substring(0, charCount));
          charCount += 1;
        }
      }, 20);
    }, 500);

    $('[data-behavior~=logo-icons]').addClass('expand');

    $('[data-behavior~=animate-click]').on('click', function() {
      $('[data-behavior~=logo-icons]').removeClass('expand').addClass('shrink');
      setTimeout(function() {
        $('[data-behavior~=logo-icons]').removeClass('shrink').addClass('expand');
      }, 250)
    });
  }
});
