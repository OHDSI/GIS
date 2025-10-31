# Building the GIS Documentation Site

The OHDSI GIS Working Group documentation is built using RMarkdown. The source files are in `rmd/` and the rendered HTML outputs to `docs/` for GitHub Pages hosting.

## Quick Start

### Use Docker to build the site

Here's a reference Dockerfile (for arm64 systems running Apple silicon)
```
FROM arm64v8/r-base

RUN mkdir /GIS
WORKDIR /GIS

RUN apt update && \
    apt install \
    -y --no-install-recommends pandoc \
                               libxml2-dev \
							   libfontconfig1-dev \
							   libharfbuzz-dev \
							   libfribidi-dev
							  

RUN Rscript -e "install.packages('xml2')" && \
    Rscript -e "install.packages('svglite')" && \
	Rscript -e "install.packages('kableExtra')" && \
	Rscript -e "install.packages('dplyr')" && \
	Rscript -e "install.packages('readr')"


CMD["Rscript", "build-site.R"]
```

Here's a Docker command for the above file - run in the directory where you clone the GIS repo:

```
docker build -t gis-site-builder . && docker run --name build-site -v ./GIS:/GIS gis-site-builder
```


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
