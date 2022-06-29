FROM node:20-alpine

WORKDIR /app
COPY package.json ./
COPY server.js ./

RUN addgroup -S app && adduser -S app -G app
USER app

ENV PORT=8080
EXPOSE 8080

CMD ["node", "server.js"]
