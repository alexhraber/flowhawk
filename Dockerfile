# FlowHawk Network Security Monitor - Multi-stage Docker Image
FROM golang:1.25-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates make

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o flowhawk ./cmd/flowhawk

# Production image
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates curl

# Create app user (can be overridden at runtime)
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Create directories
RUN mkdir -p /app/configs /app/logs
COPY --from=builder /app/flowhawk /app/
COPY configs/development.yaml /app/configs/

# Change ownership
RUN chown -R appuser:appgroup /app

WORKDIR /app

# Default to non-root user (can be overridden with --user root at runtime)
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/api/stats || exit 1

# Run the application
CMD ["./flowhawk", "-config", "/app/configs/flowhawk.yaml"]

# Labels
LABEL org.opencontainers.image.title="FlowHawk Network Security Monitor"
LABEL org.opencontainers.image.description="Real-time network security monitoring using eBPF"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Your Organization"
LABEL org.opencontainers.image.licenses="MIT"
