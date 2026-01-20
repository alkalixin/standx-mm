# Multi-platform Dockerfile for StandX Maker Bot
# Supports: linux/amd64, linux/arm64, linux/arm/v7

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for pynacl and other packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directory for logs
RUN mkdir -p /app/logs

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Default command
CMD ["python", "main.py"]
