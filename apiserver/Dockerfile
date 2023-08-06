FROM node:16-alpine as builder

WORKDIR /usr/src/app

COPY package.json .
COPY package-lock.json .
RUN npm install -g typescript
RUN npm install
COPY . .

RUN npm run build

FROM node:16-alpine as runner

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/package.json .
COPY --from=builder /usr/src/app/package-lock.json .

RUN npm install --production

COPY --from=builder /usr/src/app/dist .

CMD ["node", "index.js"]
