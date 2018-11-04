# Dockerfile for node environment

FROM node:9-alpine AS build

# optionally install gyp tools for native builds
RUN apk add --update --no-cache \
    python \
    make \
    g++

# CI build steps
ADD . /src
WORKDIR /src
RUN npm install
RUN npm run build
RUN npm prune --production


# next step after build
FROM node:9-alpine

# install curl for healthcheck
RUN apk add --update --no-cache curl

ENV PORT=3000
EXPOSE $PORT

ENV DIR=/usr/src/service
WORKDIR $DIR

# Copy files from build stage
COPY --from=build /src/package.json package.json
COPY --from=build /src/package-lock.json package-lock.json
COPY --from=build /src/node_modules node_modules
COPY --from=build /src/.next .next

HEALTHCHECK --interval=5s \
            --timeout=5s \
            --retries=6 \
            CMD curl -fs http://localhost:$PORT/_health || exit 1

CMD ["npm", "run", "start"]

