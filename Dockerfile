# ETAPA PREPARATIVA - ESTAGIO BASE
FROM node:20 AS base

# CADA FROM É UM ESTAGIO ESPECIFICO, E UM ESTAGIO PODE UTILIZAR RECURSOS
# DE UM ESTAGIO PASSADO

RUN npm i -g pnpm

FROM base AS dependencies

# É IMPORTANTE DEFINIR UM DIRETORIO DE TRABALHO SENÃO ELE VAI TRABALHAR
# NA BASE DO SISTEMA OPERACIONAL
WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml ./

# EM TEMPO DE BUILD - PREPARAÇÃO
RUN pnpm install

FROM base AS build

WORKDIR /usr/src/app

COPY . .
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

RUN pnpm build
RUN pnpm prune --prod

FROM node:20-alpine3.19 AS deploy

WORKDIR /usr/src/app

RUN npm i -g pnpm prisma

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

# AS INFORMAÇÕES ABAIXO SÃO SENSIVEIS E NÃO PODEM FICAR EXPOSTAS DESSA FORMA
# FEITO AQUI APENAS PARA VISUALIZAÇÃO E TESTES
# REMOVER ELES DAQUI PARA COLOCAR NO docker-compose.yaml
# ENV DATABASE_URL="file:./db.sqlite"
# ENV API_BASE_URL="http://localhost:3333"

RUN pnpm prisma generate

EXPOSE 3333

CMD [ "pnpm", "start" ]

# EM TEMPO DE CONTAINER - EXECUÇÃO
# pnpm start