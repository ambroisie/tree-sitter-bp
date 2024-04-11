.PHONY: all
all:
	tree-sitter generate

.PHONY: test
test: all
	tree-sitter test --apply-all-captures

.PHONY: update-tests
update-tests: all
	tree-sitter test -u --apply-all-captures

playground:
	nix shell pkgs#emscripten --command tree-sitter build-wasm
	tree-sitter playground
