# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/rspec'
require 'paper_trail/frameworks/rspec'
require 'shoulda/matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
['', 'engines/**/'].each do |dir|
  Dir[Rails.root.join("#{dir}spec/support/**/*.rb")].each { |f| require f }
end

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Capybara.register_driver :firefox do |app|
  options = %w[--headless --disable-gpu]
  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    clear_local_storage: true,
    options: Selenium::WebDriver::Firefox::Options.new(
      args: options
    )
  )
end

Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :firefox
Selenium::WebDriver.logger

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include ActiveSupport::Testing::TimeHelpers

  # config.include ControllerMacros, type: :controller
  config.include ControllerMacros, type: :feature
  config.include ControllerMacros, type: :request
  # config.include SelecterHelper,   type: :feature
  # config.include SupportHelper,    type: :controller
  # config.include SupportHelper,    type: :feature
  # config.include SupportHelper,    type: :request
  config.include FactoryBot::Syntax::Methods
  # config.include WaitForAjax, type: :feature

  config.example_status_persistence_file_path = Rails.root.join('spec', '.examples.txt')

  config.before(:suite) do
    begin
      FactoryBot.lint
    ensure
      DatabaseCleaner.clean_with(:truncation)
      FileUtils.rm_rf(Dir.glob(Attachment.pwd + '*'))
      FileUtils.rm_rf(Rails.root.join('tmp/storage'))
    end
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # When using JS, the Poltergeist driver needs to access the DB from an external
  # process, if we're in a transaction, stuff like newly created Users won't be
  # available to the driver
  #
  # See:
  #  https://github.com/plataformatec/devise/wiki/How-To:-Test-with-Capybara
  #  http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    # with.test_framework :minitest
    # with.test_framework :minitest_4
    # with.test_framework :test_unit

    # Choose one or more libraries:
    # with.library :active_record
    # with.library :active_model
    # with.library :action_controller
    # Or, choose the following (which implies all of the above):
    with.library :rails
  end
end

ActiveJob::Base.queue_adapter = :test
