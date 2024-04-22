package tree_sitter_bp_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"git.belanyi.fr/ambroisie/tree-sitter-bp"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_bp.Language())
	if language == nil {
		t.Errorf("Error loading Bp grammar")
	}
}
