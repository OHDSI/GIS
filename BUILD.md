# Building the GIS Documentation Site

The OHDSI GIS Working Group documentation is built using RMarkdown. The source files are in `rmd/` and the rendered HTML outputs to `docs/` for GitHub Pages hosting.

## Quick Start

### Option 1: Using the Build Script (Recommended)

```bash
Rscript build-site.R
```

### Option 2: Using R Console

```r
# From repository root
setwd("rmd")
rmarkdown::render_site(encoding = "UTF-8")
```

### Option 3: Using RStudio

1. Open RStudio
2. Set working directory to `rmd/` folder
3. Open any `.Rmd` file
4. Click **Build** tab → **Build Website**

## Prerequisites

### Required R Packages

```r
install.packages("rmarkdown")
install.packages("knitr")
```

## Site Configuration

The site is configured via `rmd/_site.yml`:

- **Output Directory**: `../docs` (for GitHub Pages)
- **Theme**: Cosmo
- **Custom CSS**: `style.css`
- **Navbar**: Configured with Home, Getting Started, Gaia, Vocabulary, How to, Getting Involved, Developer, Project Management

## File Structure

```
GIS/
├── rmd/               # Source RMarkdown files
│   ├── _site.yml      # Site configuration
│   ├── index.Rmd      # Home page
│   ├── developer.Rmd  # Developer hub
│   ├── sections/      # Content sections
│   └── ...
├── docs/              # Generated HTML (published to GitHub Pages)
│   ├── index.html
│   ├── developer.html
│   └── ...
└── build-site.R       # Build script
```

## Building Individual Files

To render a single RMarkdown file:

```r
rmarkdown::render("rmd/developer.Rmd", output_dir = "docs")
```

## Viewing the Site Locally

After building, open `docs/index.html` in a web browser:

```bash
# macOS
open docs/index.html

# Linux
xdg-open docs/index.html

# Windows
start docs/index.html
```

Or use a local web server:

```bash
# Python 3
cd docs && python3 -m http.server 8000

# R
servr::httd("docs")
```

Then visit: http://localhost:8000

## Publishing to GitHub Pages

The `docs/` folder is configured for GitHub Pages:

1. Build the site: `Rscript build-site.R`
2. Commit changes to `docs/` directory
3. Push to GitHub: `git push origin main`
4. GitHub Pages automatically publishes from `docs/` folder on `main` branch

Site URL: https://ohdsi.github.io/GIS

## Troubleshooting

### "Package 'rmarkdown' not found"

```r
install.packages("rmarkdown")
```

### "Pandoc not found"

RMarkdown requires Pandoc. Install via:

- **RStudio**: Comes bundled with Pandoc
- **Standalone**: https://pandoc.org/installing.html
- **Homebrew (macOS)**: `brew install pandoc`
- **apt (Ubuntu)**: `sudo apt install pandoc`

### Build fails with encoding errors

Ensure UTF-8 encoding:

```r
rmarkdown::render_site(encoding = "UTF-8")
```

### Changes not appearing

Clear the cache and rebuild:

```bash
rm -rf docs/
Rscript build-site.R
```

## Development Workflow

1. Edit source files in `rmd/`
2. Build site: `Rscript build-site.R`
3. Preview locally: Open `docs/index.html`
4. Commit both `rmd/` source and `docs/` output
5. Push to GitHub

## Continuous Integration

Consider adding a GitHub Action to automatically build the site on push:

```yaml
# .github/workflows/build-site.yml
name: Build RMarkdown Site
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Install dependencies
        run: Rscript -e 'install.packages("rmarkdown")'
      - name: Build site
        run: Rscript build-site.R
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
```

## Contact

For documentation issues, contact the GIS Working Group leadership or file an issue at https://github.com/OHDSI/GIS/issues
