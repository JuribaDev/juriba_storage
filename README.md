# Juriba Storage

A flexible and scalable blob storage service built with Ruby on Rails, designed with clean architecture principles.

## Features

- **Multiple Storage Backends**: Store blobs in MinIo (aws S3) compatible, database, or local filesystem
- **Architecture**: Domain-driven design with clear separation of concerns
- **API Authentication**: Secure API with JWT-based authentication
- **Idempotent Operations**: Support for idempotent requests via request IDs
- **Caching**: Performance optimization with Redis caching
- **Docker Support**: Easy deployment with Docker and Docker Compose

## Architecture

The application follows DDD architecture principles with distinct layers:

### Domain Layer
- Contains business logic and entities
- Defines interfaces for repositories and services
- Independent of frameworks and external services

### Application Layer
- Implements use cases using domain entities
- Orchestrates the flow of data between domain and infrastructure
- Contains service classes that coordinate operations

### Infrastructure Layer
- Implements interfaces defined in the domain layer
- Provides concrete implementations for repositories and services
- Handles external concerns like database access, caching, and external storage

### API Layer
- Exposes RESTful endpoints for blob operations
- Handles authentication and request validation
- Translates between HTTP requests/responses and application services

## Storage Strategies

The application supports multiple storage backends through a strategy pattern:

### S3 Storage
- Uses AWS S3 or compatible services (like MinIO)
- Configurable endpoint, credentials, and bucket
- Suitable for production environments

### Database Storage
- Stores blob data directly in the PostgreSQL database
- Simple setup with no external dependencies
- Good for small to medium-sized blobs

### Local Filesystem Storage
- Stores blobs on the local filesystem
- Configurable storage path
- Useful for development and testing

## Running with Docker Compose

### Prerequisites
- Docker and Docker Compose installed
- Git (to clone the repository)

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd juriba_storage
   ```

2. Create an environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file to configure your environment:
   - Set `SECRET_KEY_BASE` (generate with `rails secret`)
   - Set `ACCESS_SECRET_KEY` for JWT authentication
   - Configure database credentials
   - Choose a storage backend (`STORAGE_TYPE=s3|database|local`)
   - Configure the selected storage backend

4. Start the application:

   For production:
   ```bash
   docker compose up -d
   ```

   For development:
   ```bash
   docker compose -f docker-compose.dev.yml up -d
   ```

5. Initialize the database:
   ```bash
   docker compose exec app rails db:create db:migrate db:seed
   ```

6. Access the application Swagger api at http://localhost:3000/api-docs

### Docker Compose Services

The Docker Compose setup includes the following services:

- **app**: The Rails application
- **postgres**: PostgreSQL database
- **redis**: Redis for caching
- **minio**: MinIO S3-compatible object storage (when using S3 backend)

## API Endpoints

### Authentication

```
POST /api/v1/login
```
Request body:
```json
{
  "username": "your_username",
  "password": "your_password"
}
```
Response:
```json
{
  "access_token": "jwt_token",
  "access_token_expires_at": "2025-05-06T18:12:22Z",
  "username": "your_username"
}
```

### Blob Operations

#### Store a Blob
```
POST /api/v1/blobs
```
Headers:
```
Authorization: Bearer your_jwt_token
Idempotency-Key: unique_request_id  (required)
```
Request body:
```json
{
  "id": "uuid-format-id",
  "data": "base64_encoded_data"
}
```

#### Generate a UUID
```
GET /api/v1/blobs/generate_uuid
```
Response:
```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000"
}
```
This endpoint does not require authentication and is useful for testing or when you need a valid UUID for blob creation.

#### Retrieve a Blob
```
GET /api/v1/blobs/:id
```
Headers:
```
Authorization: Bearer your_jwt_token
```

## Configuration

The application can be configured through environment variables:

### Rails Configuration
- `SECRET_KEY_BASE`: Secret key for Rails
- `RAILS_ENV`: Environment (development, test, production)

### Database Configuration
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name

### Authentication
- `ACCESS_SECRET_KEY`: Secret key for JWT tokens

### Storage Configuration
- `STORAGE_TYPE`: Storage backend to use (s3, database, filesystem)

#### Filesystem Storage
- `FILESYSTEM_STORAGE_PATH`: Path to store files

#### S3 Storage (or MinIO)
- `MINIO_ENDPOINT`: S3 endpoint URL
- `MINIO_ROOT_USER`: S3 access key
- `MINIO_ROOT_PASSWORD`: S3 secret key
- `MINIO_BUCKET_NAME`: S3 bucket name
- `MINIO_REGION`: S3 region
- `MINIO_USE_SSL`: Whether to use SSL
- `MINIO_FORCE_PATH_STYLE`: Whether to use path-style URLs

## Development

### Testing

#### Test Environment Setup
The test environment uses:
- SQLite database (instead of PostgreSQL used in development/production)
- Local filesystem storage (configured in `.env.test`)
- In-memory caching

To prepare your environment for testing, ensure you have:
1. Copied the example test environment file if you need to customize it:
   ```bash
   cp .env.test .env.test.local  # Optional: only if you need custom test settings
   ```

#### Running Tests

##### Without Docker
If you're developing without Docker, you can run tests directly:
```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/path/to/file_spec.rb

# Run tests matching a specific description
bundle exec rspec -e "description text"
```

#### Test Organization
Tests are organized by component type:
- `spec/models/` - ActiveRecord model tests
- `spec/controllers/` - Controller tests
- `spec/domain/` - Domain entity tests
- `spec/infrastructure/` - Infrastructure implementation tests
- `spec/application/` - Application service tests

Some tests are designed to run without Rails dependencies and are suffixed with `_no_rails_spec.rb`.


### Code Quality
```bash
docker-compose exec app bundle exec rubocop
```


