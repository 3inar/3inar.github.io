import os
import re
import subprocess
import time

from pathlib import Path

NOTES_DIR = "notes"
BIB_FILE = "../bibliography/references.bib"
HEADER_FILE = "meta/_header.html" 
FOOTER_FILE = "meta/_footer.html"
MENU_FILE = "meta/_menu.html"


# convenience function. guess what it does
def read_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.read()

def convert_md_to_html(md_file_info):
    html_file_path = md_file_info['path'].with_suffix('.html')
    
    header_html = read_file(HEADER_FILE)
    menu_html = read_file(MENU_FILE)
    footer_html = read_file(FOOTER_FILE)

    # last modified
    modified = time.strftime('%Y.%m.%d', time.localtime(md_file_info['modified']))
    footer_html = f"\n\n<small>this file last touched { modified }</small>" + \
        footer_html

    # put title in title
    title_match = re.search(r'<title>(.*?)</title>', header_html)
    if title_match and md_file_info['title']:
        original_title = title_match.group(1)
        new_title = original_title + " : " + md_file_info['title']
        header_html = header_html.replace(original_title, new_title)
    
    # Build body from markdown w/ pandoc
    pandoc_process = subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'html', '--mathjax', '--citeproc', '--bibliography', BIB_FILE],
        input=md_file_info['contents_updated'],
        text=True,
        capture_output=True
    )

    body_html = pandoc_process.stdout

    # append header/footer
    full_html = "\n\n".join([header_html, menu_html,  body_html, footer_html])

    # Write the Pandoc output to the HTML file
    with open(html_file_path, 'w', encoding='utf-8') as file:
        file.write(full_html)


# finds the first header of some markdown 
def extract_title(content):
    header_pattern = re.compile(r'^#+\s+(.*)', re.MULTILINE)
    match = header_pattern.search(content)

    if match:
        return match.group(1).strip() 
    return None 

# only certain files are eligible for backlinks
def backlink_valid(path):
    return NOTES_DIR in path.parts and re.match(r'^\d{12}\.md$', path.name)

def placeholder_to_link(content):
    # Regular expression pattern to match links of the type [[123456789012]]
    link_pattern = re.compile(r'\[\[(\d{12})\]\]')
    return link_pattern.sub(r'[(\1)](/notes/\1.html)', content)

# information not really used but I might want to make an RSS feed at some point
def extract_first_paragraph(content):
    # This pattern looks for any text that follows the first header and ends before the next header
    # or two consecutive newlines, which typically denote the end of a paragraph.
    paragraph_pattern = re.compile(r'(?:\n\n|\r\n\r\n|^)([^#]+?)(?:\n\n|\r\n\r\n|#)', re.DOTALL)
    match = paragraph_pattern.search(content)
    if match:
        return match.group(1).strip()  
    return None


def main():
    # find all .md files in this dir and subdirs
    current_folder = Path('.')
    raw_md_files = list(current_folder.rglob('*.md'))
    
    md_files = []
    identifier_to_title = {}

    # find all relevant information from .md files
    for md_file in raw_md_files:
        content = read_file(md_file)
        title = extract_title(content)
        first_paragraph = extract_first_paragraph(content)
        
        created = os.stat(md_file).st_birthtime 
        modified = os.stat(md_file).st_mtime

        # Store file information in the md_files list
        md_files.append({'path': md_file, 
                         'title': title,
                         'first_paragraph': first_paragraph,
                         'created': created, 
                         'modified': modified,
                         'contents': content})

        # Update the identifier to title mapping
        identifier = md_file.stem
        identifier_to_title[identifier] = title

    # process .md files: 
    # * add backlinks 
    # * translate placeholder links to real links
    # * add a line about last modification
    # * build static .html
    for md_file in md_files:
        md_file['contents_updated'] = md_file['contents']

        # add backlinks
        if backlink_valid(md_file['path']):
            backlinks = []
            # Search for backlinks in all valid files
            for other_file in md_files:
                if other_file['path'] != md_file['path'] and backlink_valid(other_file['path']):
                    # Check if the current file's identifier is in the other file's contents
                    if f"[[{md_file['path'].stem}]]" in other_file['contents']:
                        backlinks.append(f"* [[{other_file['path'].stem}]] {other_file['title']}")

            # Append the list of backlinks to the current file's contents
            if backlinks:
                md_file['contents_updated'] = md_file['contents_updated'] + \
                                                "\n\n**Backlinks:**\n\n" + "\n".join(backlinks)

        # translate placeholder links to real links
        md_file['contents_updated'] = placeholder_to_link(md_file['contents_updated'])


        convert_md_to_html(md_file)

if __name__ == '__main__':
    main()
