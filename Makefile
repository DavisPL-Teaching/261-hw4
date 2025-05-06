.PHONY: view build show-input-files pre post aux spellcheck full clean copy
.DEFAULT_GOAL: view

MAIN_TEX = hw4.tex
MAIN_AUX = hw4.aux
MAIN_OUT = hw4.pdf

SRC_FILES = $(wildcard *.tex)
BIB_FILES = $(wildcard *.bib)
IMG_FILES = $(wildcard img/*) $(wildcard img/*/*)

PDFLATEX_EXIT = -interaction=nonstopmode -halt-on-error
TEXFOT_QUIET = --quiet --ignore "^This is pdfTeX" --ignore "^Output written on" --ignore "^Transcript written on"

INDENT = sed 's_^_    _'
RED = printf "\033[0;31m"
YELLOW = printf "\033[1;33m"
RESET = printf "\033[0m"

# Build and view the PDF
view: build copy
	open $(MAIN_OUT)

# Build the PDF
build: build/$(MAIN_OUT) copy

# Run pdflatex with prettified (less verbose) output
# Requires texfot (which I believe is installed by default with most distros)
build/$(MAIN_OUT): $(SRC_FILES) $(BIB_FILES) $(IMG_FILES)
	mkdir -p build
	cp -R *.tex build/
	@echo "Entering build..."
	@cd build \
	&& pdflatex $(PDFLATEX_EXIT) $(MAIN_TEX) > /dev/null \
	&& $(YELLOW) \
	&& bibtex --terse $(MAIN_AUX) | $(INDENT) \
	&& $(RESET) \
	&& pdflatex $(MAIN_TEX) > /dev/null \
	&& $(YELLOW) \
	&& texfot $(TEXFOT_QUIET) pdflatex $(MAIN_TEX) | $(INDENT) \
	&& $(RESET) \
	|| ( $(RED) \
	&& printf "===== Error =====\n" | $(INDENT) \
	&& texfot $(TEXFOT_QUIET) pdflatex $(PDFLATEX_EXIT) $(MAIN_TEX) | $(INDENT) \
	&& $(RESET) \
	&& cd .. \
	&& rm -rf build/ \
	&& exit 1 )

copy: build/$(MAIN_OUT)
	cp build/$(MAIN_OUT) $(MAIN_OUT)

# Show all sources picked up by the Makefile (useful for debugging)
show-input-files:
	@echo "=== tex sources ==="
	@echo $(SRC_FILES)
	@echo "=== bib ==="
	@echo $(BIB_FILES)
	@echo "=== images and figures ==="
	@echo $(IMG_FILES)

# Auxiliary data from pre-build .tex/.bib files
pre:
	scripts/update_totals.sh
	scripts/extract_abstract.sh
	scripts/update_wordclouds.sh

# Auxiliary data from post-build .pdf/.aux files
post: build
	scripts/update_bibstats.sh || true
	scripts/update_fonts.sh

# Build all auxiliary data and stats
aux: pre post

# Run aspell (with input file of whitelisted words)
spellcheck:
	scripts/spellcheck.sh

# Build final version for publishing
full: clean spellcheck pre build post

# Clean up
# Separating out build/ simplifies cleanup considerably.
# Notice we don't have to enumerate a long list of TeX-related files, like:
# rm -f *.aux *.toc *.out *.log *.bbl *.blg *.pdf *.temp *.lof *.lot
clean:
	rm -rf build/
	rm -f data/*.temp
	rm -rf src_arXiv/
	rm -f arXiv.zip
