FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY much-to-do/Server/MuchToDo/go.mod much-to-do/Server/MuchToDo/go.sum ./

COPY much-to-do/Server/MuchToDo/ .

RUN go mod download

RUN go build -o main ./cmd/api

FROM alpine:latest

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
