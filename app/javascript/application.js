// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import '@hotwired/turbo-rails'
import 'datatables'
import 'stupidtable'

// Forms by default will not be submitted with turbo unless the
// data-turbo="true" attribute is present. See: https://github.com/hotwired/turbo/pull/419
Turbo.setFormMode("optin")
