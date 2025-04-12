FROM node:22-alpine

WORKDIR /app

RUN npm install -g pnpm@9.14.2

COPY package*.json ./

RUN pnpm install

COPY . .

RUN pnpm run build

EXPOSE 3000

CMD ["pnpm", "run", "start:prod"] 
