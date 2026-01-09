# Use official Ruby image
FROM ruby:3.2-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libsodium-dev \
    libopus-dev \
    ffmpeg \
    git \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN pip3 install --no-cache-dir --break-system-packages yt-dlp

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install --without development test

# Copy application code
COPY . .

# Create a non-root user
RUN useradd -m -u 1000 botuser && \
    chown -R botuser:botuser /app

USER botuser

# Run the bot
CMD ["ruby", "bot.rb"]
