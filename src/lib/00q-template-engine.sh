#!/usr/bin/env bash
# src/lib/00q-template-engine.sh — Template Engine (v4.5.0)
# Generates project boilerplates from templates.
set -euo pipefail

# ── Template configuration ───────────────────────────────────────────────────
_TEMPLATE_DIR="${SCRIPT_DIR}/src/templates"
_TEMPLATE_REGISTRY="${DL_CACHE}/templates.json"

# ── Built-in templates ──────────────────────────────────────────────────────
# Using function-based lookup for bash 3.2 compatibility
_TEMPLATE_NAMES=(
  "nextjs" "react" "vue" "svelte" "angular"
  "express" "fastify" "nestjs" "django" "fastapi" "flask" "spring" "rails" "laravel"
  "graphql" "grpc" "rest"
  "react-native" "flutter" "ionic"
  "electron" "tauri"
  "cli-node" "cli-python" "cli-go" "cli-rust"
  "lib-ts" "lib-py" "lib-go" "lib-rust"
  "docker" "k8s" "terraform" "ansible"
  "ml-python" "llm-app" "rag"
  "saas" "blog" "ecommerce" "dashboard"
)

_template_description() {
  case "$1" in
    # Web frameworks
    nextjs) echo "Next.js 14+ with TypeScript, Tailwind, App Router" ;;
    react) echo "React 18+ with Vite, TypeScript" ;;
    vue) echo "Vue 3 with Vite, TypeScript, Pinia" ;;
    svelte) echo "SvelteKit with TypeScript" ;;
    angular) echo "Angular 17+ with TypeScript" ;;
    # Backend frameworks
    express) echo "Express.js with TypeScript, Prisma" ;;
    fastify) echo "Fastify with TypeScript, Prisma" ;;
    nestjs) echo "NestJS with TypeScript, Prisma" ;;
    django) echo "Django with Python, PostgreSQL" ;;
    fastapi) echo "FastAPI with Python, SQLAlchemy" ;;
    flask) echo "Flask with Python, SQLAlchemy" ;;
    spring) echo "Spring Boot with Java, PostgreSQL" ;;
    rails) echo "Ruby on Rails with PostgreSQL" ;;
    laravel) echo "Laravel with PHP, MySQL" ;;
    # API
    graphql) echo "GraphQL API with Apollo Server" ;;
    grpc) echo "gRPC service with Protocol Buffers" ;;
    rest) echo "REST API with Express, OpenAPI" ;;
    # Mobile
    react-native) echo "React Native with Expo" ;;
    flutter) echo "Flutter with Dart" ;;
    ionic) echo "Ionic with Angular/React/Vue" ;;
    # Desktop
    electron) echo "Electron with React, TypeScript" ;;
    tauri) echo "Tauri with React, Rust" ;;
    # CLI
    cli-node) echo "CLI tool with Node.js, Commander" ;;
    cli-python) echo "CLI tool with Python, Click" ;;
    cli-go) echo "CLI tool with Go, Cobra" ;;
    cli-rust) echo "CLI tool with Rust, Clap" ;;
    # Libraries
    lib-ts) echo "TypeScript library with Rollup" ;;
    lib-py) echo "Python library with Poetry" ;;
    lib-go) echo "Go library" ;;
    lib-rust) echo "Rust library with Cargo" ;;
    # Infrastructure
    docker) echo "Docker Compose multi-service setup" ;;
    k8s) echo "Kubernetes deployment manifests" ;;
    terraform) echo "Terraform infrastructure as code" ;;
    ansible) echo "Ansible playbook" ;;
    # AI/ML
    ml-python) echo "ML project with PyTorch, scikit-learn" ;;
    llm-app) echo "LLM application with LangChain" ;;
    rag) echo "RAG system with vector database" ;;
    # Full-stack
    saas) echo "SaaS starter with auth, payments, DB" ;;
    blog) echo "Blog with Next.js, MDX" ;;
    ecommerce) echo "E-commerce with Next.js, Stripe" ;;
    dashboard) echo "Admin dashboard with React, Charts" ;;
    *) echo "" ;;
  esac
}

# ── List templates ──────────────────────────────────────────────────────────
# Usage: _template_list [category]
_template_list() {
  local category="${1:-all}"

  section "Available Templates"

  for name in "${_TEMPLATE_NAMES[@]}"; do
    local desc
    desc=$(_template_description "$name")
    local cat="${name%%-*}"
    
    if [ "$category" = "all" ] || [ "$cat" = "$category" ]; then
      printf "  %-20s %s\n" "$name" "$desc"
    fi
  done
}

# ── Generate project from template ──────────────────────────────────────────
# Usage: _template_generate "nextjs" "my-app" "/path/to/output"
_template_generate() {
  local template="$1" name="$2" output="${3:-.}"

  section "Generating: $name ($template)"

  if [ -z "$(_template_description "$template")" ]; then
    warn "Unknown template: $template"
    return 1
  fi

  local project_dir="$output/$name"
  
  if [ -d "$project_dir" ]; then
    warn "Directory already exists: $project_dir"
    return 1
  fi

  mkdir -p "$project_dir"

  case "$template" in
    nextjs)
      _template_nextjs "$project_dir"
      ;;
    react)
      _template_react "$project_dir"
      ;;
    vue)
      _template_vue "$project_dir"
      ;;
    express|fastify|nestjs)
      _template_node_api "$project_dir" "$template"
      ;;
    django|fastapi|flask)
      _template_python_api "$project_dir" "$template"
      ;;
    cli-node)
      _template_cli_node "$project_dir"
      ;;
    cli-python)
      _template_cli_python "$project_dir"
      ;;
    cli-go)
      _template_cli_go "$project_dir"
      ;;
    docker)
      _template_docker "$project_dir"
      ;;
    *)
      _template_generic "$project_dir" "$template"
      ;;
  esac

  log "Project generated: $project_dir"
}

# ── Next.js template ────────────────────────────────────────────────────────
_template_nextjs() {
  local dir="$1"

  # package.json
  cat > "$dir/package.json" <<'EOF'
{
  "name": "nextjs-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "typescript": "^5.3.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "eslint": "^8.56.0",
    "eslint-config-next": "^14.0.0",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/jest-dom": "^6.1.0"
  }
}
EOF

  # tsconfig.json
  cat > "$dir/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./src/*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

  # tailwind.config.ts
  cat > "$dir/tailwind.config.ts" <<'EOF'
import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: { extend: {} },
  plugins: [],
}
export default config
EOF

  # src/app/layout.tsx
  mkdir -p "$dir/src/app"
  cat > "$dir/src/app/layout.tsx" <<'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Next.js App',
  description: 'Created with opencode_initializer',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
EOF

  # src/app/page.tsx
  cat > "$dir/src/app/page.tsx" <<'EOF'
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">Welcome to Next.js</h1>
      <p className="mt-4 text-lg text-gray-600">
        Get started by editing src/app/page.tsx
      </p>
    </main>
  )
}
EOF

  # src/app/globals.css
  cat > "$dir/src/app/globals.css" <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

  # .gitignore
  cat > "$dir/.gitignore" <<'EOF'
node_modules/
.next/
out/
.env
.env.local
.env.production
.vercel
*.tsbuildinfo
next-env.d.ts
EOF

  # README.md
  cat > "$dir/README.md" <<'EOF'
# Next.js App

Created with opencode_initializer.

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Scripts

- `npm run dev` — Start development server
- `npm run build` — Build for production
- `npm start` — Start production server
- `npm run lint` — Run ESLint
- `npm test` — Run tests
EOF

  log "Next.js template generated"
}

# ── React template ──────────────────────────────────────────────────────────
_template_react() {
  local dir="$1"

  cat > "$dir/package.json" <<'EOF'
{
  "name": "react-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src --ext ts,tsx",
    "test": "vitest",
    "test:ui": "vitest --ui"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.1.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/jest-dom": "^6.1.0",
    "eslint": "^8.56.0",
    "eslint-plugin-react": "^7.33.0",
    "eslint-plugin-react-hooks": "^4.6.0"
  }
}
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/App.tsx" <<'EOF'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
EOF

  cat > "$dir/src/main.tsx" <<'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

  mkdir -p "$dir/src/pages"
  cat > "$dir/src/pages/Home.tsx" <<'EOF'
export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <h1 className="text-4xl font-bold">Welcome to React</h1>
      <p className="mt-4 text-lg text-gray-600">
        Get started by editing src/pages/Home.tsx
      </p>
    </div>
  )
}
EOF

  cat > "$dir/src/index.css" <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

  cat > "$dir/vite.config.ts" <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
EOF

  cat > "$dir/.gitignore" <<'EOF'
node_modules/
dist/
.env
.env.local
*.tsbuildinfo
EOF

  log "React template generated"
}

# ── Vue template ────────────────────────────────────────────────────────────
_template_vue() {
  local dir="$1"

  cat > "$dir/package.json" <<'EOF'
{
  "name": "vue-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src --ext ts,vue",
    "test": "vitest"
  },
  "dependencies": {
    "vue": "^3.4.0",
    "vue-router": "^4.2.0",
    "pinia": "^2.1.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vue-tsc": "^1.8.0",
    "vitest": "^1.1.0",
    "eslint": "^8.56.0",
    "eslint-plugin-vue": "^9.19.0"
  }
}
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/App.vue" <<'EOF'
<script setup lang="ts">
import { RouterView } from 'vue-router'
</script>

<template>
  <RouterView />
</template>
EOF

  cat > "$dir/src/main.ts" <<'EOF'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
EOF

  mkdir -p "$dir/src/views"
  cat > "$dir/src/views/Home.vue" <<'EOF'
<script setup lang="ts">
</script>

<template>
  <div class="flex min-h-screen flex-col items-center justify-center">
    <h1 class="text-4xl font-bold">Welcome to Vue</h1>
    <p class="mt-4 text-lg text-gray-600">
      Get started by editing src/views/Home.vue
    </p>
  </div>
</template>
EOF

  cat > "$dir/vite.config.ts" <<'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
})
EOF

  log "Vue template generated"
}

# ── Node.js API template ────────────────────────────────────────────────────
_template_node_api() {
  local dir="$1" framework="$2"

  cat > "$dir/package.json" <<EOF
{
  "name": "${framework}-api",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src --ext ts",
    "test": "vitest"
  },
  "dependencies": {
    "$framework": "latest",
    "prisma": "^5.7.0",
    "@prisma/client": "^5.7.0",
    "zod": "^3.22.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/jsonwebtoken": "^9.0.0",
    "@types/bcryptjs": "^2.4.0",
    "typescript": "^5.3.0",
    "tsx": "^4.7.0",
    "vitest": "^1.1.0",
    "eslint": "^8.56.0"
  }
}
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/index.ts" <<EOF
import { $framework } from '$framework'

const app = $framework()
const port = process.env.PORT || 3000

app.get('/', (req, res) => {
  res.json({ message: 'Hello from $framework!' })
})

app.listen(port, () => {
  console.log(\`Server running on port \${port}\`)
})
EOF

  log "$framework template generated"
}

# ── Python API template ─────────────────────────────────────────────────────
_template_python_api() {
  local dir="$1" framework="$2"

  cat > "$dir/pyproject.toml" <<EOF
[project]
name = "${framework}-api"
version = "0.1.0"
description = "API built with $framework"
requires-python = ">=3.11"

[project.dependencies]
${framework} = "latest"
sqlalchemy = ">=2.0"
alembic = ">=1.13"
pydantic = ">=2.5"
uvicorn = ">=0.25"

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-asyncio>=0.23",
    "httpx>=0.25",
    "ruff>=0.1",
]
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/main.py" <<EOF
from $framework import $framework

app = $framework()

@app.get("/")
async def root():
    return {"message": "Hello from $framework!"}

@app.get("/health")
async def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

  log "$framework template generated"
}

# ── CLI Node template ───────────────────────────────────────────────────────
_template_cli_node() {
  local dir="$1"

  cat > "$dir/package.json" <<'EOF'
{
  "name": "cli-tool",
  "version": "0.1.0",
  "bin": {"cli": "./dist/index.js"},
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "lint": "eslint src --ext ts"
  },
  "dependencies": {
    "commander": "^11.1.0",
    "chalk": "^5.3.0",
    "inquirer": "^9.2.0",
    "ora": "^7.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.3.0",
    "tsx": "^4.7.0"
  }
}
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/index.ts" <<'EOF'
#!/usr/bin/env node
import { Command } from 'commander'
import chalk from 'chalk'

const program = new Command()

program
  .name('cli')
  .description('CLI tool')
  .version('0.1.0')

program
  .command('hello')
  .description('Say hello')
  .argument('[name]', 'name to greet', 'World')
  .action((name) => {
    console.log(chalk.green(`Hello, ${name}!`))
  })

program.parse()
EOF

  log "CLI Node template generated"
}

# ── CLI Python template ─────────────────────────────────────────────────────
_template_cli_python() {
  local dir="$1"

  cat > "$dir/pyproject.toml" <<'EOF'
[project]
name = "cli-tool"
version = "0.1.0"
description = "CLI tool built with Click"
requires-python = ">=3.11"

[project.dependencies]
click = ">=8.1"
rich = ">=13.0"
typer = ">=0.9"

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "ruff>=0.1",
]
EOF

  mkdir -p "$dir/src"
  cat > "$dir/src/main.py" <<'EOF'
#!/usr/bin/env python3
import typer
from rich import print

app = typer.Typer()

@app.command()
def hello(name: str = "World"):
    """Say hello."""
    print(f"[green]Hello, {name}![/green]")

@app.command()
def version():
    """Show version."""
    print("cli-tool v0.1.0")

if __name__ == "__main__":
    app()
EOF

  log "CLI Python template generated"
}

# ── CLI Go template ─────────────────────────────────────────────────────────
_template_cli_go() {
  local dir="$1"

  cat > "$dir/go.mod" <<'EOF'
module cli-tool

go 1.21

require (
    github.com/spf13/cobra v1.8.0
    github.com/fatih/color v1.16.0
)
EOF

  mkdir -p "$dir/cmd"
  cat > "$dir/main.go" <<'EOF'
package main

import (
    "fmt"
    "os"

    "github.com/fatih/color"
    "github.com/spf13/cobra"
)

func main() {
    rootCmd := &cobra.Command{
        Use:   "cli",
        Short: "CLI tool",
        Long:  "A CLI tool built with Cobra",
    }

    helloCmd := &cobra.Command{
        Use:   "hello [name]",
        Short: "Say hello",
        Args:  cobra.MaximumNArgs(1),
        Run: func(cmd *cobra.Command, args []string) {
            name := "World"
            if len(args) > 0 {
                name = args[0]
            }
            color.Green("Hello, %s!", name)
        },
    }

    rootCmd.AddCommand(helloCmd)

    if err := rootCmd.Execute(); err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}
EOF

  log "CLI Go template generated"
}

# ── Docker template ─────────────────────────────────────────────────────────
_template_docker() {
  local dir="$1"

  cat > "$dir/docker-compose.yml" <<'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/app
    depends_on:
      - db
      - redis

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
EOF

  cat > "$dir/Dockerfile" <<'EOF'
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
CMD ["npm", "start"]
EOF

  cat > "$dir/.dockerignore" <<'EOF'
node_modules
dist
.git
.env
*.md
EOF

  log "Docker template generated"
}

# ── Generic template ────────────────────────────────────────────────────────
_template_generic() {
  local dir="$1" template="$2"

  cat > "$dir/README.md" <<EOF
# $template Project

Created with opencode_initializer.

## Getting Started

TODO: Add setup instructions

## Structure

TODO: Add project structure

## Scripts

TODO: Add available scripts
EOF

  cat > "$dir/.gitignore" <<'EOF'
node_modules/
dist/
build/
.env
.env.local
*.log
.DS_Store
EOF

  log "Generic template generated"
}

# ── Export functions ─────────────────────────────────────────────────────────
export -f _template_list _template_generate _template_nextjs _template_react \
  _template_vue _template_node_api _template_python_api _template_cli_node \
  _template_cli_python _template_cli_go _template_docker _template_generic 2>/dev/null || true
