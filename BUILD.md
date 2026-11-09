# Simeon-D-Korkpor-Resume — Build Notes

## One-line install (fresh Ubuntu/Debian VM)

```bash
curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/Simeon-D-Korkpor-Resume/main/setup.sh | bash
```

The script installs its own prerequisites — git and curl (base tools), plus Node.js 20.x (with npm) from the official NodeSource apt repository — through apt/official sources, then clones the repo (into `~/repos/Simeon-D-Korkpor-Resume` when run outside a checkout), copies `.env.example` to `.env` if needed, runs `npm install`, and runs `npm run build`. On non-apt platforms it falls back to checking for the tools and printing install guidance.

Alternative (clone and run):

```bash
git clone https://github.com/UncleD0886475978/Simeon-D-Korkpor-Resume.git
cd Simeon-D-Korkpor-Resume
./setup.sh
```

- **Repo:** https://github.com/UncleD0886475978/Simeon-D-Korkpor-Resume
- **Public status:** Public (contents listed and raw files fetched via the GitHub connector without restriction).
- **Stack actually found:** TypeScript / Node — specifically a Shopify Hydrogen storefront template (Remix + Vite), not a static resume page. Proof: `package.json` (name `hydrogen-storefront`, `"type": "module"`, dependencies `@shopify/hydrogen`, `@remix-run/react`, react 18; devDeps typescript, vite; engines `node >= 18`), scripts `build: remix vite:build`, `dev: shopify hydrogen dev --codegen`, `preview: netlify serve`, `typecheck: tsc`, `lint: eslint …`; also `vite.config.ts`, `tsconfig.json`, `server.ts`, `app/`, `package-lock.json`, and `netlify.toml` (build command `npm run build`, publish `dist/client`). README is the upstream "Hydrogen template: Skeleton" doc.
- **What setup.sh does:** Bootstraps base tools (git, curl) and Node.js 20.x from NodeSource on Ubuntu/Debian (satisfying the `>=18` engine requirement), finds or clones the repo, copies `.env.example` to `.env` if none exists (Hydrogen needs store settings; `mock.shop` works for the demo), runs `npm install`, then runs `npm run build` because a build script exists in package.json, and prints the dev/preview/typecheck commands taken from package.json scripts.
- **Issue it prevents:** Treating this as a plain TypeScript resume page and missing that it's a Hydrogen app — without the `.env` store settings and a Node ≥ 18 `npm install` + build, `npm run dev` fails before serving anything.
