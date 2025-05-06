# Set up the dependency injection container
# Changed from after_initialize to ensure container is available for other initializers

# Explicitly require the container class to prevent autoloading issues
require_relative "../../app/infrastructure/container"

# Eager load all the necessary classes to prevent autoloading issues
Rails.application.config.to_prepare do
  # First load domain errors
  require_relative "../../app/domain/errors"

  # Then load domain interfaces namespace
  require_relative "../../app/domain/interfaces"

  # Then load domain interfaces
  %w[
    app/domain/interfaces/configuration_service
    app/domain/interfaces/cache_service
    app/domain/interfaces/idempotency_service
    app/domain/interfaces/blob_storage_strategy
    app/domain/interfaces/storage_strategy_factory
    app/domain/interfaces/blob_repository
    app/domain/entities/blob
  ].each { |file| require_relative "../../#{file}" }

  # Load persistence namespace
  require_relative "../../app/infrastructure/persistence"

  # Load persistence models
  %w[
    app/infrastructure/persistence/blob_tracker
    app/infrastructure/persistence/stored_blob
  ].each { |file| require_relative "../../#{file}" }

  # Then load infrastructure strategies namespace
  require_relative "../../app/infrastructure/strategies"

  # Then load strategy implementations
  %w[
    app/infrastructure/strategies/s3_storage
    app/infrastructure/strategies/local_storage
    app/infrastructure/strategies/database_storage
  ].each { |file| require_relative "../../#{file}" }

  # Then load other infrastructure implementations
  %w[
    app/infrastructure/config/settings
    app/infrastructure/services/configuration_service
    app/infrastructure/services/cache_service
    app/infrastructure/services/idempotency_service
    app/infrastructure/factories/storage_factory
    app/infrastructure/repositories/blob_repository
    app/application/services/blob_service
  ].each { |file| require_relative "../../#{file}" }

  # Register configuration service
  Infrastructure::Container.register(:config_service) do
    Infrastructure::Services::ConfigurationService.new
  end

  # Register cache service
  Infrastructure::Container.register(:cache_service) do
    Infrastructure::Services::CacheService.new(
      config_service: Infrastructure::Container.resolve(:config_service)
    )
  end

  # Register idempotency service
  Infrastructure::Container.register(:idempotency_service) do
    Infrastructure::Services::IdempotencyService.new(
      config_service: Infrastructure::Container.resolve(:config_service)
    )
  end

  # Register storage factory
  Infrastructure::Container.register(:storage_factory) do
    Infrastructure::Factories::StorageFactory.new(
      config_service: Infrastructure::Container.resolve(:config_service)
    )
  end

  # Register blob repository
  Infrastructure::Container.register(:blob_repository) do
    Infrastructure::Repositories::BlobRepository.new(
      storage_factory: Infrastructure::Container.resolve(:storage_factory)
    )
  end

  # Register blob service
  Infrastructure::Container.register(:blob_service) do
    Application::Services::BlobService.new(
      blob_repository: Infrastructure::Container.resolve(:blob_repository),
      storage_factory: Infrastructure::Container.resolve(:storage_factory),
      cache_service: Infrastructure::Container.resolve(:cache_service),
      idempotency_service: Infrastructure::Container.resolve(:idempotency_service),
      config_service: Infrastructure::Container.resolve(:config_service)
    )
  end
end
