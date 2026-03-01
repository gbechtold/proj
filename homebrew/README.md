# Homebrew Tap for proj

## Setup

To use this as a Homebrew tap, create a separate repo `gbechtold/homebrew-proj` with the `Formula/` directory.

```bash
# Users install with:
brew tap gbechtold/proj
brew install proj
```

## Release workflow

1. Tag a release: `git tag v1.0.0 && git push --tags`
2. Get the tarball SHA: `curl -sL https://github.com/gbechtold/proj/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256`
3. Update `sha256` in `Formula/proj.rb`
4. Push to `homebrew-proj` repo
