# ═══════════════════════════════════════════════════════════════
# STAGE 1: Builder
# Installs dependencies — has build tools, bigger image
# ═══════════════════════════════════════════════════════════════

# linux/amd64 required — ECS Fargate runs on Intel
# Your Mac is ARM so we must specify the platform
FROM --platform=linux/amd64 node:20-alpine AS builder

WORKDIR /build

# Copy dependency files first
# Docker caches this layer — if package.json hasn't changed,
# it skips npm ci on the next build (much faster!)
COPY app/package*.json ./

# Install exact versions from package-lock.json
RUN npm ci

# ═══════════════════════════════════════════════════════════════
# STAGE 2: Runtime
# Only what's needed to RUN the app — tiny image
# ═══════════════════════════════════════════════════════════════

FROM --platform=linux/amd64 node:20-alpine

WORKDIR /app

# Copy ONLY installed packages from builder
# Build tools, npm cache etc are left behind
COPY --from=builder /build/node_modules ./node_modules

# Copy app source code
COPY app/ ./

# Create non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app
USER appuser

# Document which port the app listens on
EXPOSE 3000

# Start the app
CMD ["node", "index.js"]