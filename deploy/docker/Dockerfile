# Build stage
FROM elixir:1.18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git npm nodejs

# Set environment
ENV MIX_ENV=prod

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy dependency files first (for caching)
COPY backend/mix.exs backend/mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets and compile them
COPY backend/assets ./assets
COPY backend/priv ./priv
RUN cd assets && npm ci && npm run deploy
RUN mix phx.digest

# Copy all source code
COPY backend/lib ./lib
COPY backend/config ./config

# Compile the application
RUN mix compile

# Build the release
RUN mix release

# Runtime stage
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs postgresql-client

WORKDIR /app

# Create non-root user
RUN addgroup -g 1000 buttonlog && \
    adduser -u 1000 -G buttonlog -s /bin/sh -D buttonlog

# Copy the release from builder
COPY --from=builder --chown=buttonlog:buttonlog /app/_build/prod/rel/buttonlog ./

USER buttonlog

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1

# Start the application
CMD ["bin/buttonlog", "start"]
