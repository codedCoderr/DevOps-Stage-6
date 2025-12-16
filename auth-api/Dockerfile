# Stage 1: Build
FROM golang:1.21 AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o auth-api .

# Stage 2: Minimal runtime image
FROM alpine:latest
WORKDIR /root/
COPY --from=build /app/auth-api .
EXPOSE 8080
CMD ["./auth-api"]