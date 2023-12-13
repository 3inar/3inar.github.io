# Makefile to convert all .md files to .html using pandoc with preprocessing

# Source directory for Markdown files
SRC_DIR := .

# Find all .md files in the source directory and its subdirectories
MD_FILES := $(shell find $(SRC_DIR) -name '*.md')

# Replace the .md extension with .html for all found files
HTML_FILES := $(MD_FILES:.md=.html)

META_FILES := meta/_header.html meta/_footer.html \
							meta/_menu.html meta/main.css meta/syntax.css
BIB_FILE := ~/Dropbox/knowledge/bibliography/references.bib


# Default target
all: $(HTML_FILES)

# Rule to convert a .md file to .html
%.html: %.md $(META_FILES)
	@# Preprocess the .md file to replace [[yyyymmddHHMM]] with a Markdown link
	@sed 's/\[\[\([0-9]\{12\}\)\]\]/[(\1)](\/notes\/\1.html)/g' $< > $@.tmp.md
	@# Convert the temporary preprocessed file to .html
	@pandoc  --mathjax --citeproc --bibliography $(BIB_FILE) $@.tmp.md -o $@.tmp.html
	@# Create a temporary footer with the last modification date
	@echo "<small>current document last modified $$(stat -f '%Sm' -t '%Y.%m.%d' $<)</small>" > $@.tmp.footer.html
	@cat meta/_footer.html >> $@.tmp.footer.html
	@# Concatenate header, generated HTML content, and temporary footer into the final HTML file
	@cat meta/_header.html meta/_menu.html $@.tmp.html $@.tmp.footer.html > $@
	@# Remove the temporary files
	@rm -f $@.tmp.md $@.tmp.html $@.tmp.footer.html

# Clean target to remove all generated .html files except those starting with an underscore
clean:
	find $(SRC_DIR) -name '*.html' ! -name '_*.html' -exec rm {} +

serve: all
	@echo "Starting Python HTTP server..."
	@python3 -m http.server 

.PHONY: all clean serve
