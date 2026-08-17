# GitHub - deepseek-ai/deepseek-harness: DeepSeek Harness: Everything is a Plugin. · GitHub

> Source: https://github.com/deepseek-ai/deepseek-harness
> Cached: 2026-08-17T08:27:28.559Z

---

# DeepSeek Harness

[](#deepseek-harness)
English | [中文](/deepseek-ai/deepseek-harness/blob/master/README.zh.md)

DeepSeek Harness (`dsh`) is an open-source agent harness developed by [DeepSeek AI](https://deepseek.com).

It uses an architecture where **everything is a plugin**, and is powered by [Cordis](https://github.com/cordiverse/cordis), whose design is described in [*A Programming Paradigm for Spatiotemporal Composability*](https://github.com/cordiverse/paper).

## Developer preview

[](#developer-preview)
DeepSeek Harness is currently in *developer preview* and is iterating rapidly. **THERE WILL BE COMPATIBILITY-BREAKING CHANGES.**

## Run

[](#run)
### Run from `npm`

[](#run-from-npm)
Install `Node.js`, then run:

npx @deepseek-ai/dsh web
The command starts the Web UI, served at `http://127.0.0.1:3080` by default. See [Web UI guide](/deepseek-ai/deepseek-harness/blob/master/docs/user/guide/index.md).

### Run from source

[](#run-from-source)
To run from a repository checkout:

git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness
pnpm install
pnpm run build
pnpm dsh web
## Community and support

[](#community-and-support)

- Feel free to submit feedback or bug reports through [GitHub Discussions](https://github.com/deepseek-ai/deepseek-harness/discussions).

- Add the [`dsh-plugin`](https://github.com/topics/dsh-plugin) topic to your plugin repository for discoverability.

- Join [DeepSeek Harness Discord community](https://discord.gg/Ycq5dCaS4).

## Contributing

[](#contributing)
See [CONTRIBUTING.md](/deepseek-ai/deepseek-harness/blob/master/CONTRIBUTING.md).

## Development

[](#development)
Start with the [development guide](/deepseek-ai/deepseek-harness/blob/master/docs/development.md) and [architecture documentation](/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md).

For agents, follow [AGENTS.md](/deepseek-ai/deepseek-harness/blob/master/AGENTS.md).

## License

[](#license)
[MIT](/deepseek-ai/deepseek-harness/blob/master/LICENSE)

Third-party dependencies and their licenses are disclosed in [THIRD_PARTY_NOTICES.md](/deepseek-ai/deepseek-harness/blob/master/THIRD_PARTY_NOTICES.md).