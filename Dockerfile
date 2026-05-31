# Build image
FROM golang:1.25 AS build
WORKDIR /openrouter-bot
COPY . .
RUN go mod download
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /openrouter-bot/openrouter-bot

# Final image
FROM alpine:3.22
WORKDIR /openrouter-bot

RUN apk add --no-cache netcat-openbsd

COPY --from=build /openrouter-bot/config.yaml ./
COPY --from=build /openrouter-bot/lang/ ./lang/
COPY --from=build /openrouter-bot/openrouter-bot ./
RUN mkdir logs

EXPOSE 8080

# МАГИЯ ТУТ: перед запуском мы берем все системные переменные, которые ты вбил в Back4app, 
# и насильно записываем их в реальный файл .env, который так сильно хочет этот бот.
ENTRYPOINT sh -c "env > .env && while true; do echo -e 'HTTP/1.1 200 OK\n\n Preved Back4app' | nc -l -p 8080; done & /openrouter-bot/openrouter-bot"
