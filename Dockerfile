#ARG consul=0.7.5
#ARG envconsul=0.7.3
ARG node=10.15

# Build stage

FROM node:$node as build

COPY bin /code/bin
COPY package.json /code/package.json

WORKDIR /code

# Final stage

FROM node:$node
COPY --from=build /code /code
CMD ["node", "/code/bin/app.js" ]
