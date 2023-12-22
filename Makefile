# Makefile to convert all .md files to .html using pandoc with preprocessing

# Source directory for Markdown files
SRC_DIR := .

# Find all .md files in the source directory and its subdirectories
MD_FILES := $(shell find $(SRC_DIR) -name '*.md')

# Replace the .md extension with .html for all found files
HTML_FILES := $(MD_FILES:.md=.html)

META_FILES := meta/_header.html meta/_footer.html \
							meta/_menu.html meta/main.css meta/syntax.css


# Default target
all: $(HTML_FILES)

# Rule to convert a .md file to .html
%.html: %.md $(META_FILES)
	python3 build.py

# Clean target to remove all generated .html files except those starting with an underscore
clean:
	find $(SRC_DIR) -name '*.html' ! -name '_*.html' -exec rm {} +

serve: all
	@echo "Starting Python HTTP server..."
	@python3 -m http.server 

.PHONY: all clean serve
