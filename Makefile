# Makefile to convert all .md files to .html using pandoc with preprocessing

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
	@# Preprocess the .md file to replace [[yyyymmddHHMM]] with a Markdown link
	@sed 's/\[\[\([0-9]\{12\}\)\]\]/[\1](\/notes\/\1.html)/g' $< > $@.tmp.md
	@# Get the last modification date of the .md file and append it to the temporary file
	@echo "\n\n##### current document last modified: $$(stat -f '%Sm' -t '%Y%m%d%H%M' $<)" >> $@.tmp.md
	@# Convert the temporary preprocessed file to .html
	@pandoc --mathml $@.tmp.md -o $@.tmp.html
	@# Concatenate header, generated HTML content, and footer into the final HTML file
	@cat _header.txt $@.tmp.html _footer.txt > $@
	@# Remove the temporary files
	@rm -f $@.tmp.md $@.tmp.html

# Clean target to remove all generated .html files
clean:
	find $(SRC_DIR) -name '*.html' -exec rm {} +

.PHONY: all clean
