FROM node:10

LABEL "com.github.actions.name"="Auto Assign"
LABEL "com.github.actions.description"="Add reviewers/assignees to pull requests when pull requests are opened."
LABEL "com.github.actions.icon"="user-plus"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/DiagVN/auto-assign"
LABEL "homepage"="https://github.com/DiagVN/auto-assign"
LABEL "maintainer"="JUANMA"

ENV PATH=$PATH:/app/node_modules/.bin
WORKDIR /app
COPY . .
RUN npm install --production && npm run build

ENTRYPOINT ["npm", "start"]
# CMD ["/app/lib/index.js"]
