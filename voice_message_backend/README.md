# Voice Message Backend

A backend service for handling voice messages built with FastAPI. This project leverages the [ell-ai](pyproject.toml) package for AI processing and uses environment variables (via [python-dotenv](pyproject.toml)) for configuration.

## Features

- **Voice Message Processing:** Processes incoming voice message trascriptions.
- **REST API:** Built with FastAPI for a modern asynchronous experience.
- **AI Integration:** Uses OpenAI and ell-ai for advanced message analysis.

## Requirements

- Python 3.13+
- Dependencies managed via Poetry ([pyproject.toml](pyproject.toml))

## Setup

1. **Clone the repository:**

   ```sh
   git clone <repository-url>
   cd voice-message-backend
   ```
2. **Install dependencies using Poetry:**

    ```sh
    poetry install
    ```
3. **Configure Environment Variables:**

    Create a .env file in the root directory. See [.env.example](.env.example) for reference.

## Running the Application

You can run the application in different modes:

- **Development Mode:**

  ```sh
  poetry run dev
  ```

- **Production Mode:**

  ```sh
  poetry run start
  ```

## Testing

**Run the tests with:**
    ```sh
    poetry run pytest
    ```

## License

This project is licensed under the MIT License.