# catrepo

`catrepo` creates a single text file from a Git repository by concatenating all tracked text files. It is handy when you want to hand a compact repository snapshot to an LLM, another tool, or another person in one document.

## What It Does

- Resolves the repository name via Git and writes the output to `<repo-name>-all.txt`
- Reads only Git-tracked files
- Detects binary files via `git ls-files --eol` and skips them
- Skips files that no longer exist or cannot be decoded as text
- Intentionally leaves out `.gitignore` and `stack.yaml.lock`

## Requirements

- `git` must be installed
- The tool must be run inside a Git working tree
- `stack` is the easiest way to run it locally

## Usage

With Stack:

```bash
stack run
```

Or run the executable after building:

```bash
stack build
stack exec catrepo
```

After that, a file such as `catrepo-all.txt` will be created in the project directory.

## Output Format

Each included file is wrapped with a small header and footer:

```text
--- File: src/Main.hs ---
...
--- End of src/Main.hs ---
```

## Notes

- Only tracked files are included; untracked files are ignored.
- Generated output (`catrepo-all.txt`) is ignored in this repository via `.gitignore`.
