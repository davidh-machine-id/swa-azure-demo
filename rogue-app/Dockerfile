# Build stage
FROM golang:1.26.4-alpine3.23 AS builder
WORKDIR /build
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o rogue-app .

# Runtime stage
FROM alpine:3.23
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /build/rogue-app .

EXPOSE 8081

CMD ["./rogue-app"]
