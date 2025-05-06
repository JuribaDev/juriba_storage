# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Explicitly require domain interfaces before strategy files
require_relative '../app/domain/interfaces/blob_storage_strategy'
require_relative '../app/domain/interfaces/storage_strategy_factory'
require_relative '../app/domain/interfaces/configuration_service'
require_relative '../app/domain/interfaces/cache_service'
require_relative '../app/domain/interfaces/idempotency_service'
require_relative '../app/domain/interfaces/blob_repository'

# Explicitly require domain errors
require_relative '../app/domain/errors'

# Explicitly require strategy implementations
require_relative '../app/infrastructure/strategies/s3_storage'
require_relative '../app/infrastructure/strategies/local_storage'
require_relative '../app/infrastructure/strategies/database_storage'

# Require support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
# Add additional requires below this line. Rails is not loaded until this point!

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
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  # Only try to maintain schema if we're using ActiveRecord and not SQLite
  if defined?(ActiveRecord) && ActiveRecord::Base.connection.adapter_name.downcase != 'sqlite3'
    ActiveRecord::Migration.maintain_test_schema!
  end
rescue => e
  puts "Database connection error: #{e.to_s.strip}"
  puts "Tests will continue without database schema check"
end

RSpec.configure do |config|
  # Disable ActiveRecord completely for tests that don't need it
  config.use_active_record = false

  # Skip ActiveRecord setup
  config.before(:suite) do
    # No database setup needed
  end

  # Skip database connection for tests that don't need it
  config.around(:each) do |example|
    begin
      example.run
    rescue ActiveRecord::DatabaseConnectionError => e
      # If the test doesn't actually need the database, we can ignore this error
      if example.metadata[:requires_db] == false
        # Just continue without the database
        true
      else
        # Re-raise the error for tests that do need the database
        raise e
      end
    end
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
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
end
