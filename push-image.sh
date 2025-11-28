#!/bin/bash
set -e

# Service directories
dirs=("frontend" "auth-api" "todos-api" "users-api" "log-message-processor")

# Corresponding image names
images=("codedcoderrr/frontend" "codedcoderrr/auth" "codedcoderrr/todos" "codedcoderrr/users" "codedcoderrr/log-message-processor")

TAG="latest"

echo "Ensuring buildx builder exists..."
if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
  docker buildx create --name mybuilder --use
else
  docker buildx use mybuilder
fi

echo "Logging into Docker Hub..."
docker login

# Build and push all images
for i in "${!dirs[@]}"; do
  dir="${dirs[$i]}"
  IMAGE="${images[$i]}"

  echo "Building and pushing multi-arch image for $dir -> $IMAGE:$TAG"

  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t $IMAGE:$TAG \
    --push "./$dir"
done

echo "✅ All multi-arch images pushed successfully!"
