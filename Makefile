# Makefile to convert all .md files to .html using pandoc

# Source directory for Markdown files
SRC_DIR := .

# Find all .md files in the source directory and its subdirectories
MD_FILES := $(shell find $(SRC_DIR) -name '*.md')

# Replace the .md extension with .html for all found files
HTML_FILES := $(MD_FILES:.md=.html)

# Default target
all: $(HTML_FILES)

# Rule to convert a .md file to .html
%.html: %.md
	pandoc $< -o $@

# Clean target to remove all generated .html files
clean:
	find $(SRC_DIR) -name '*.html' -exec rm {} +

.PHONY: all clean
