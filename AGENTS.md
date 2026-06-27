# AGENTS.md

## Ruby and Bundler

- This repository declares its Ruby version in `.ruby-version`.
  Before running any Ruby, Bundler, test, lint, or setup command, run `ruby --version` and verify it matches `.ruby-version`.
- If the active Ruby does not match `.ruby-version`, stop and fix the runtime first.
  Do not run `bundle install`, `bundle update`, or `bundle exec rake` against the wrong Ruby.
- Treat `Gemfile.lock` as unchanged unless the user explicitly asks for a dependency or platform update.
  If `Gemfile.lock` changes unexpectedly, stop, inspect the diff, and revert only that accidental lockfile change.
- When installing missing dependencies for verification, use frozen Bundler:
  `BUNDLE_FROZEN=true bundle install`.
  This allows missing locked gems to be installed while preventing Bundler from rewriting `Gemfile.lock`.
- Use the Bundler version recorded under `BUNDLED WITH` in `Gemfile.lock`.
  If that Bundler version is missing for the active Ruby, install that exact Bundler version after confirming the Ruby version is correct.
- Run project checks through Bundler.
  The README documents the full verification command as `bundle exec rake`.
  In agent/sandbox environments, prefer `BUNDLE_FROZEN=true bundle exec rake`.
- If RuboCop cannot write to `~/.cache` in a sandbox, set `RUBOCOP_CACHE_ROOT` to a writable temporary path such as `/private/tmp/ruby-openai-rubocop-cache`.
  Do not change repository configuration just to work around a local sandbox cache permission issue.
