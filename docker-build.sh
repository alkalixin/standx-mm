#!/bin/bash
# Build multi-platform Docker image for StandX Maker Bot

IMAGE_NAME="standx-maker-bot"
TAG="latest"

echo "Building multi-platform Docker image: ${IMAGE_NAME}:${TAG}"
echo "Supported platforms: linux/amd64, linux/arm64, linux/arm/v7"
echo ""

# Check if buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo "Error: Docker Buildx is not available."
    echo "Please install Docker Buildx or use Docker Desktop."
    exit 1
fi

# Create builder if not exists
if ! docker buildx inspect multiplatform-builder > /dev/null 2>&1; then
    echo "Creating buildx builder: multiplatform-builder"
    docker buildx create --name multiplatform-builder --use
fi

# Use the builder
docker buildx use multiplatform-builder

# Build for multiple platforms
echo "Building for multiple platforms..."
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t ${IMAGE_NAME}:${TAG} \
    --load \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "Image: ${IMAGE_NAME}:${TAG}"
    echo ""
    echo "To run the bot:"
    echo "  docker-compose up -d"
    echo ""
    echo "Or run directly:"
    echo "  docker run -v ./config.yaml:/app/config.yaml:ro -v ./logs:/app/logs ${IMAGE_NAME}:${TAG}"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
