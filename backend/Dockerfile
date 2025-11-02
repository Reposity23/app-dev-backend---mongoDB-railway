# Use the official Dart SDK image as the base
FROM dart:stable

# Set the working directory inside the container
WORKDIR /app

# Copy the dependency files first
COPY pubspec.yaml pubspec.lock ./

# Get the dependencies
RUN dart pub get

# Copy the rest of the backend application code
# This copies bin/, lib/, etc. into the container
COPY . .

# The server.dart file is already set to listen on the PORT
# environment variable, which Render will provide.
# We just need to define the command to run the server.
CMD ["dart", "run", "bin/server.dart"]