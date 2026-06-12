# 1. Build stage: Compile the Go application
FROM golang:1.26.4-alpine3.23 AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o demo-app main.go

# 2. Runtime stage: Minimal Alpine image with the compiled binary
FROM alpine:3.23
WORKDIR /app
RUN apk add --no-cache curl bash
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /build/demo-app .
COPY --chown=appuser:appgroup . .
USER appuser
EXPOSE 8080
CMD ["./demo-app"]
