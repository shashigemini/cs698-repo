# Website

This website is built using [Docusaurus](https://docusaurus.io/), a modern static website generator.

## Installation

```bash
npm ci
```

## Local Development

```bash
npm start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

## Build

```bash
npm run build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

## Deployment

Deployment to GitHub Pages is handled by [`.github/workflows/deploy-docs.yml`](C:/Users/shash/Documents/GitHub/cs698-repo/.github/workflows/deploy-docs.yml). The site sources live under `apps/docs-site/`.
