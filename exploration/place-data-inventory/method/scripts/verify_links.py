#!/usr/bin/env python3
"""Part A of the verification design (docs/discovery/verify-prompt-2026-10-21.md):
reachability and URL-health checks, scripted, no LLM in the loop.

Inputs (all under docs/discovery/):
  inventory-working.csv                 594 curated rows (raw fields)
  leads-2026-10-20.csv                  raw fields for the inferred-unit leads
  place-data-inventory-<date>.xlsx      Inventory sheet: which ids are in scope, tier, priority

Outputs:
  verify-A-<date>.csv                   one row per dataset (also the checkpoint: re-run resumes)
  verify-log.csv                        long-form history, appended, one run_id per run
  browser-queue-<date>.csv              shortlist rows that came back blocked_bot / blocked_robots
  verify-A-report-<date>.md             one-page report
  verify-changes-<date>.md              diff against the previous run_id in verify-log.csv (if any)

Rules implemented: polite User-Agent; at most 1 request per second per domain (threads run
across domains, serial within a domain); robots.txt honoured for landing pages; 20 s timeout
with one retry; landing pages fetched in full (capped at 3 MB), endpoints by HEAD or a
1 KB Range GET only; bot protection and TLS errors recorded, never bypassed.

Usage (from the workspace root):
  python docs/discovery/scripts/verify_links.py --date 2026-10-21 [--workers 12] [--limit N] [--ids a,b]
  python docs/discovery/scripts/verify_links.py --date 2026-10-21 --report-only
"""
import argparse, csv, json, os, re, sys, time, threading, html as htmlmod
from collections import Counter, defaultdict, OrderedDict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone, timedelta
from html.parser import HTMLParser
from urllib.parse import urlsplit, quote
from urllib import robotparser

import requests
import openpyxl

UA = "OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)"
TIMEOUT = 20
MIN_INTERVAL = 1.0          # seconds between requests to the same domain
DOMAIN_INTERVAL = {"web.archive.org": 2.5}  # the CDX API answers 429 at a sustained 1 request/s
PAGE_CAP = 3 * 1024 * 1024  # landing-page read cap
CHECKPOINT_EVERY = 25

HERE = os.path.dirname(os.path.abspath(__file__))
DISC = os.path.abspath(os.path.join(HERE, ".."))
OUT = DISC  # output folder; --outdir overrides (tests)

CHECKS = ["chk_link_live", "chk_redirect", "chk_tls", "chk_soft404", "chk_withdrawn",
          "chk_access_url", "chk_format_match",
          "chk_machine_metadata", "chk_persistent_id", "chk_archived"]
RAW_COLS = ["dataset_name", "organization", "sub_organization", "theme", "variables_examples",
            "geography_units", "coverage", "temporal", "versions", "format", "access_type", "license",
            "update_cadence", "source_of_listing", "evidence_url", "confidence", "last_checked", "notes",
            "in_gaia", "record_type", "health_relevance", "finest_unit", "gaia_fit", "score_note",
            "unit_basis", "unit_confidence", "unit_evidence"]
EXTRA_COLS = ["http_status", "final_url", "response_ms", "content_type", "page_title", "checked_at",
              "access_http_status", "access_final_url", "access_content_type",
              "metadata_kind", "persistent_id", "wayback_url", "wayback_date"]
SUMMARY_COLS = ["checks_applicable", "checks_passed", "checks_warned", "checks_failed", "all_passing_A", "url_health"]


def out_cols():
    cols = ["id", "tier", "priority", "site_url", "access_url"]
    for c in CHECKS:
        cols += [c, c + "_detail"]
    cols += EXTRA_COLS + SUMMARY_COLS + RAW_COLS
    return cols


# ----------------------------------------------------------------------------- politeness
_tls = threading.local()


def session():
    s = getattr(_tls, "s", None)
    if s is None:
        s = requests.Session()
        s.headers.update({"User-Agent": UA, "Accept": "text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8"})
        _tls.s = s
    return s


class DomainLimiter:
    def __init__(self):
        self._g = threading.Lock()
        self._d = {}

    def _get(self, dom):
        with self._g:
            if dom not in self._d:
                self._d[dom] = [threading.Lock(), 0.0]
            return self._d[dom]

    def __enter__(self):
        return self

    def acquire(self, dom):
        ent = self._get(dom)
        ent[0].acquire()
        wait = ent[1] + DOMAIN_INTERVAL.get(dom, MIN_INTERVAL) - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        return ent

    def release(self, ent):
        ent[1] = time.monotonic()
        ent[0].release()


LIMITER = DomainLimiter()


def domain_of(url):
    try:
        return (urlsplit(url).netloc or "").lower().split("@")[-1]
    except Exception:
        return ""


def polite_request(method, url, **kw):
    """One request, rate-limited per domain, with one retry on timeout / connection error.
    Returns (response, error_kind, error_text, elapsed_ms)."""
    dom = domain_of(url)
    kw.setdefault("timeout", TIMEOUT)
    kw.setdefault("allow_redirects", True)
    last = (None, "error", "", 0)
    retry_wait = 2
    for attempt in range(3 if dom.endswith("archive.org") else 2):
        ent = LIMITER.acquire(dom)
        t0 = time.monotonic()
        try:
            r = session().request(method, url, **kw)
            ms = int((time.monotonic() - t0) * 1000)
            if attempt == 0 and r.status_code >= 500 and not is_bot_block(r):
                r.close(); last = (r, None, "", ms); retry_wait = 3
                continue
            if r.status_code == 429 and dom.endswith("archive.org") and attempt < 2:
                r.close(); last = (r, None, "", ms); retry_wait = 60
                continue
            return r, None, "", ms
        except requests.exceptions.SSLError as e:
            return None, "tls", str(e)[:300], int((time.monotonic() - t0) * 1000)
        except requests.exceptions.TooManyRedirects as e:
            return None, "redirect_loop", str(e)[:300], int((time.monotonic() - t0) * 1000)
        except requests.exceptions.Timeout as e:
            last = (None, "timeout", str(e)[:300], int((time.monotonic() - t0) * 1000))
        except requests.exceptions.ConnectionError as e:
            txt = str(e)
            if re.search(r"NameResolutionError|getaddrinfo|Name or service not known|nodename nor servname|No address associated", txt):
                return None, "dns", txt[:300], int((time.monotonic() - t0) * 1000)
            if "Read timed out" in txt or "timed out" in txt.lower():
                last = (None, "timeout", txt[:300], int((time.monotonic() - t0) * 1000))
            else:
                last = (None, "connection", txt[:300], int((time.monotonic() - t0) * 1000))
        except requests.exceptions.InvalidURL as e:
            return None, "invalid_url", str(e)[:300], 0
        except requests.exceptions.MissingSchema as e:
            return None, "invalid_url", str(e)[:300], 0
        except requests.exceptions.InvalidSchema as e:
            return None, "invalid_url", str(e)[:300], 0
        except Exception as e:
            return None, "error", f"{type(e).__name__}: {str(e)[:250]}", int((time.monotonic() - t0) * 1000)
        finally:
            LIMITER.release(ent)
        if attempt == 0 or dom.endswith("archive.org"):
            time.sleep(retry_wait)
    return last


# ----------------------------------------------------------------------------- robots
_robots = {}
_robots_lock = threading.Lock()


def robots_allows(url):
    """True if robots.txt allows our agent to fetch url (or robots.txt is absent/unreadable)."""
    parts = urlsplit(url)
    key = f"{parts.scheme}://{parts.netloc}".lower()
    with _robots_lock:
        rp = _robots.get(key, "pending")
    if rp == "pending":
        rp = None
        r, err, _, _ = polite_request("GET", key + "/robots.txt", timeout=10)
        if r is not None and r.status_code == 200 and "html" not in (r.headers.get("Content-Type") or "").lower():
            try:
                p = robotparser.RobotFileParser()
                p.parse(r.text.splitlines())
                rp = p
            except Exception:
                rp = None
        if r is not None:
            r.close()
        with _robots_lock:
            _robots[key] = rp
    if rp is None:
        return True
    try:
        return rp.can_fetch(UA, url)
    except Exception:
        return True


# ----------------------------------------------------------------------------- domains
MULTI_SUFFIX = set("""co.uk org.uk gov.uk ac.uk me.uk net.uk nhs.uk sch.uk police.uk gov.scot gov.wales
com.au gov.au edu.au org.au net.au csiro.au co.nz govt.nz org.nz ac.nz co.za gov.za org.za ac.za
com.br gov.br org.br co.jp go.jp ac.jp or.jp co.in gov.in nic.in ac.in com.mx gob.mx org.mx
com.ar gob.ar gov.ar com.co gov.co edu.co gov.sg com.sg edu.sg com.cn gov.cn edu.cn org.cn gov.my com.my
gouv.fr gob.es gov.it gc.ca gov.hk com.hk edu.hk org.hk com.tw gov.tw edu.tw go.kr co.kr or.kr ac.kr
go.id co.id ac.id or.id go.th co.th ac.th or.th gov.ph com.ph edu.ph gov.pk edu.pk com.pk gov.bd gov.ng com.ng
gov.gh gov.ke co.ke or.ke ac.ke gov.ug co.ug gov.tz go.tz gov.et gov.eg com.eg gov.sa com.sa gov.ae ac.ae
gov.tr com.tr edu.tr org.tr gov.il co.il org.il ac.il gov.ua com.ua edu.ua gov.pl com.pl edu.pl org.pl
gov.np edu.np com.np gov.lk gov.vn edu.vn com.vn gov.kh gov.la gov.mm gov.bt""".split())


def registered_domain(host):
    host = (host or "").lower().split(":")[0]
    labels = host.split(".")
    if len(labels) <= 2:
        return host
    if ".".join(labels[-2:]) in MULTI_SUFFIX:
        return ".".join(labels[-3:])
    return ".".join(labels[-2:])


# ----------------------------------------------------------------------------- page parsing
class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title = ""
        self._title_done = False
        self._in_title = False
        self._skip = 0
        self.text = []
        self.jsonld = []
        self._in_jsonld = False
        self.metas = []
        self.links = []
        self.scripts_src = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "title":
            if not self._skip and not self._title_done:
                self._in_title = True
        elif tag in ("script", "style", "noscript", "svg"):
            self._skip += 1
            if tag == "script":
                t = (a.get("type") or "").lower()
                if "ld+json" in t:
                    self._in_jsonld = True
                if a.get("src"):
                    self.scripts_src.append(a["src"])
        elif tag == "meta":
            self.metas.append(a)
        elif tag == "link":
            self.links.append(a)

    def handle_endtag(self, tag):
        if tag == "title":
            if self._in_title:
                self._title_done = True
            self._in_title = False
        elif tag in ("script", "style", "noscript", "svg"):
            self._skip = max(0, self._skip - 1)
            if tag == "script":
                self._in_jsonld = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        if self._in_jsonld:
            self.jsonld.append(data)
        elif not self._skip:
            self.text.append(data)


def parse_html(doc):
    p = TextExtractor()
    try:
        p.feed(doc)
    except Exception:
        pass
    text = re.sub(r"\s+", " ", " ".join(p.text)).strip()
    return p, text


STOP = set("the and for of in on to a an by from with at or per data dataset datasets version set file files series this that "
           "into over under between within across via its it is are was were be been using use".split())


def sig_tokens(name):
    toks = [t for t in re.findall(r"[a-z0-9]+", (name or "").lower()) if len(t) >= 3 and not t.isdigit() and t not in STOP]
    return list(OrderedDict.fromkeys(toks))


GENERIC_TITLE = re.compile(r"(page not found|not found|404|error|access denied|forbidden|just a moment|attention required|"
                           r"service unavailable|something went wrong|oops|page doesn.t exist|no longer exists|site maintenance)", re.I)

WITHDRAWN = [
    re.compile(r"\b(dataset|data set|data|product|collection|service|tool|portal|website|platform|archive|program|programme|system|layer|feed|api|index|atlas|database|"
               r"access|updates|version \d[\d.]*)\b[^.;!?]{0,60}?\s(has been|have been|is|was|are|were|is now|has now been) "
               r"(retired|decommissioned|discontinued|deprecated|sunset|sunsetted)\b", re.I),
    re.compile(r"\bno longer (available|maintained|updated|supported|published|being (updated|maintained)|offered|provided)\b", re.I),
    re.compile(r"\b(this|the) (dataset|data set|data|product|collection|service|page|resource|site|tool|portal|website|record|layer|feed) "
               r"(has been|is|was|is now|has now been) (archived|retired|decommissioned|discontinued|deprecated|moved|removed|withdrawn|replaced)\b", re.I),
    re.compile(r"\b(dataset|data set|collection|record|product) (has been |was |is )?(withdrawn|deleted)\b", re.I),
    re.compile(r"\bdecommissioned\b", re.I),
    re.compile(r"^\s*\[?archived\]?[\s:\-–]", re.I),
    re.compile(r"\((archived|discontinued|deprecated)\)", re.I),
]
# visible-text phrases that are usually navigation, not a withdrawal notice
WITHDRAWN_NOISE = re.compile(r"(archived (datasets|data|news|items|releases|versions|content|publications)|view archived|show archived|include archived|"
                             r"archived =|is_archived|archived:|browse archived|archived link|"
                             r"(older|previous|earlier|prior|legacy|old) versions?|retired, semiretired|emeriti|retired (physicians|staff|members|scientists)|"
                             r"links? (to|that|which) .{0,40}no longer|no longer (available|supported) (in|for|on) (internet explorer|ie\b|older browsers))", re.I)

DOI_RE = re.compile(r"\b(10\.\d{4,9}/[^\s\"'<>()\[\],;]+)")
HANDLE_RE = re.compile(r"(hdl\.handle\.net/[^\s\"'<>]+|ark:/\d{5,}/[^\s\"'<>]+|purl\.org/[^\s\"'<>]+|w3id\.org/[^\s\"'<>]+)", re.I)


def find_withdrawn(title, text):
    for src, s in (("title", title), ("body", text)):
        for rx in WITHDRAWN:
            if src == "body" and rx.pattern.startswith("^"):
                continue
            m = rx.search(s)
            if m:
                a, b = max(0, m.start() - 70), min(len(s), m.end() + 70)
                ctx = s[a:b].strip()
                if src == "body" and WITHDRAWN_NOISE.search(ctx):
                    continue
                return f"{src}: \"{ctx}\""
    return ""


def detect_metadata(url, final_url, ctype, body, parser):
    """Return (result, kind, detail)."""
    kinds = []
    low = body[:600000].lower() if body else ""
    host = domain_of(final_url or url)
    if "cmr.earthdata.nasa.gov" in host and "/concepts/" in (final_url or url):
        kinds.append("CMR")
    if "json" in (ctype or ""):
        try:
            j = json.loads(body[:2000000])
            if isinstance(j, dict):
                if "stac_version" in j:
                    kinds.append("STAC")
                if j.get("success") is True and "result" in j and "help" in j:
                    kinds.append("CKAN API")
                if "@context" in j or "@type" in j:
                    kinds.append("JSON-LD")
                if "umm" in j or "meta" in j and "concept-id" in str(j.get("meta")):
                    kinds.append("CMR")
        except Exception:
            pass
    if parser is not None:
        for blob in parser.jsonld:
            if re.search(r'"@type"\s*:\s*"?(\[[^\]]*)?["\s]*(schema:)?(Dataset|DataCatalog|DataDownload)\b', blob) or '"Dataset"' in blob or "schema.org/Dataset" in blob:
                kinds.append("schema.org Dataset"); break
        else:
            if parser.jsonld:
                kinds.append("JSON-LD (other type)")
        gen = " ".join((m.get("content") or "") for m in parser.metas if (m.get("name") or "").lower() == "generator").lower()
        if "ckan" in gen or "/api/3/action/" in low or "ckan.js" in low or 'class="ckan' in low or "ckanext" in low:
            kinds.append("CKAN")
        if "dcat:" in low or "w3.org/ns/dcat" in low or any("dcat" in (l.get("href") or "").lower() for l in parser.links) or \
           any((l.get("type") or "").lower() in ("application/rdf+xml", "text/turtle", "application/ld+json") and (l.get("rel") or "").lower() in ("alternate", "describedby") for l in parser.links):
            kinds.append("DCAT")
        if "socrata" in low or re.search(r"/api/views/[a-z0-9]{4}-[a-z0-9]{4}", low):
            kinds.append("Socrata")
        if ("arcgis.com" in host or "opendata.arcgis" in host or "hub.arcgis" in host or 'hub-' in low and 'arcgis' in low) and ("datasets/" in (final_url or url) or "/maps/" in (final_url or url)):
            kinds.append("ArcGIS Hub (DCAT feed)")
        if "stac_version" in low and "STAC" not in kinds:
            kinds.append("STAC")
        og = any((m.get("property") or "").lower().startswith("og:") for m in parser.metas)
        dc = any((m.get("name") or "").lower().startswith(("dc.", "dcterms.", "citation_")) for m in parser.metas)
        if not kinds:
            if dc:
                return "warn", "", "Dublin Core / citation meta tags only"
            if og:
                return "warn", "", "OpenGraph tags only"
            return "fail", "", "no machine-readable dataset metadata found"
    if not kinds:
        return "fail", "", "no machine-readable dataset metadata found"
    strong = [k for k in kinds if k != "JSON-LD (other type)"]
    if strong:
        kind = "; ".join(OrderedDict.fromkeys(strong))
        return "pass", kind, kind
    return "warn", "JSON-LD (other type)", "JSON-LD present but no Dataset type"


def find_pid(url, access_url, body, parser):
    cands = []
    for u in (url, access_url):
        if u:
            m = DOI_RE.search(u) or HANDLE_RE.search(u)
            if m:
                cands.append(("url", m.group(0)))
    if parser is not None:
        for m in parser.metas:
            n = (m.get("name") or "").lower()
            if n in ("citation_doi", "dc.identifier", "dcterms.identifier", "doi", "prism.doi"):
                v = m.get("content") or ""
                mm = DOI_RE.search(v)
                if mm:
                    cands.append(("meta", mm.group(0)))
        for blob in parser.jsonld:
            mm = re.search(r'"(identifier|sameAs|@id|url)"\s*:\s*"[^"]*?(10\.\d{4,9}/[^"\s]+)"', blob)
            if mm:
                cands.append(("json-ld", mm.group(2)))
    if body:
        m = DOI_RE.search(body[:600000])
        if m:
            cands.append(("page", m.group(0).rstrip(".")))
        m = HANDLE_RE.search(body[:600000])
        if m:
            cands.append(("page", m.group(0)))
    if cands:
        where, pid = cands[0]
        pid = pid.rstrip(".,;)")
        return "pass", pid, f"{where}: {pid}"
    return "warn", "", "no DOI or other persistent identifier found"


FORMAT_HINTS = {
    "csv": ("text/csv", "application/csv", ".csv"), "tsv": ("text/tab", ".tsv"), "txt": ("text/plain", ".txt"),
    "xlsx": ("spreadsheetml", ".xlsx"), "xls": ("ms-excel", ".xls"), "excel": ("spreadsheetml", "ms-excel", ".xls"),
    "json": ("application/json", ".json"), "geojson": ("geo+json", "application/json", ".geojson", ".json"),
    "application/json": ("application/json",), "application/geo+json": ("geo+json", "application/json"), "text/csv": ("text/csv", ".csv"),
    "shp": ("zip", ".zip", ".shp"), "shapefile": ("zip", ".zip", ".shp"), "zip": ("zip", ".zip"),
    "gpkg": ("geopackage", "sqlite", ".gpkg", "octet-stream"), "geopackage": ("geopackage", "sqlite", ".gpkg", "octet-stream"),
    "gdb": ("zip", ".zip", ".gdb"), "geodatabase": ("zip", ".zip", ".gdb"), "fgdb": ("zip", ".zip"),
    "geotiff": ("tiff", ".tif", ".tiff"), "tif": ("tiff", ".tif"), "tiff": ("tiff", ".tif"), "cog": ("tiff", ".tif"), "raster": ("tiff", ".tif", ".nc", ".img"),
    "netcdf": ("netcdf", ".nc", "octet-stream"), "nc": ("netcdf", ".nc"), "nc4": ("netcdf", ".nc"),
    "hdf": ("hdf", ".hdf", ".h5", ".he5", "octet-stream"), "hdf5": ("hdf", ".h5", ".hdf"), "hdf-eos": ("hdf", ".hdf"),
    "kml": ("vnd.google-earth", ".kml", ".kmz"), "kmz": ("vnd.google-earth", ".kmz"),
    "parquet": (".parquet", "octet-stream"), "geoparquet": (".parquet", "octet-stream"),
    "pdf": ("application/pdf", ".pdf"), "xml": ("xml", ".xml"), "gml": ("gml", "xml", ".gml"),
    "html": ("text/html",), "web": ("text/html",), "wms": ("xml", "json", "text/html", "image/"), "wfs": ("xml", "json", "text/html", "image/"),
    "wcs": ("xml", "json"), "ogc": ("xml", "json"), "api": ("json", "xml", "text/html"), "rest": ("json", "xml", "text/html"),
    "arcgis geoservices rest api": ("json", "text/html"), "esri rest": ("json", "text/html"), "geoservices": ("json", "text/html"),
    "s3": ("xml", "json", "text/html"), "sqlite": ("sqlite", ".sqlite", ".db"), "dbf": (".dbf",), "dta": (".dta",), "sav": (".sav",), "rda": (".rda", ".rdata"),
    "pmtiles": (".pmtiles",), "mbtiles": (".mbtiles",), "jpg": ("jpeg", ".jpg"), "png": ("image/png", ".png"), "grib": ("grib", ".grib", ".grb"),
    "dbase": (".dbf",), "ascii": ("text/plain", ".asc", ".txt"), "asc": (".asc", "text/plain"), "img": (".img",), "las": (".las", ".laz"),
    "ods": ("opendocument", ".ods"), "rdf": ("rdf", ".rdf"), "ttl": ("turtle", ".ttl"), "sparql": ("sparql", "json", "xml"),
    "docx": ("wordprocessingml", ".docx"), "doc": ("msword", ".doc"), "feather": (".feather",), "mat": (".mat",),
}
NOT_FORMATS = {"request", "toolbox", "unknown", "varies", "various", "multiple", "other", "n/a", "na", "none", "", "see", "notes"}


def format_match(stated, ctype, access_final):
    toks = [t.strip().lower() for t in re.split(r"[;,/|]| and |\s{2,}", stated or "") if t.strip()]
    toks = [t for t in toks if t not in NOT_FORMATS]
    if not toks:
        return "n.a.", "no stated format to compare" if not (stated or "").strip() else f"stated format not a file format ({stated})"
    ctype = (ctype or "").lower().split(";")[0].strip()
    path = urlsplit(access_final or "").path.lower()
    ext = os.path.splitext(path)[1]
    hints = []
    for t in toks:
        h = FORMAT_HINTS.get(t)
        if h is None:
            for k, v in FORMAT_HINTS.items():
                if len(k) > 2 and k in t:
                    h = v; break
        if h:
            hints.extend(h)
    for h in hints:
        if h.startswith(".") and ext == h:
            return "pass", f"extension {ext} matches {stated}"
        if not h.startswith(".") and ctype and h in ctype:
            return "pass", f"content-type {ctype} matches {stated}"
    if not hints:
        return "warn", f"stated format not recognised ({stated}); got {ctype or 'no content-type'}"
    if "html" in ctype:
        return "warn", f"html landing page (format {stated} stated); endpoint serves text/html"
    if "zip" in ctype or ext == ".zip":
        return "warn", f"zip archive; contents not inspected (stated {stated})"
    if not ctype or "octet-stream" in ctype:
        return "warn", f"ambiguous: content-type {ctype or 'missing'}, extension {ext or 'none'} vs stated {stated}"
    return "fail", f"content-type {ctype} contradicts stated format {stated}"


# ----------------------------------------------------------------------------- checks
def is_bot_block(r):
    if r is None:
        return False
    if r.status_code in (401, 403, 429):
        return True
    if r.status_code == 202:  # challenge / queue page (HDX, AWS WAF): an empty or script-only body
        return True
    if r.status_code in (503, 406, 418):
        h = {k.lower(): v for k, v in r.headers.items()}
        if "cf-mitigated" in h or "cloudflare" in (h.get("server") or "").lower() or "akamai" in (h.get("server") or "").lower():
            return True
    return False


def read_capped(r, cap=PAGE_CAP):
    chunks, n = [], 0
    try:
        for ch in r.iter_content(65536):
            chunks.append(ch); n += len(ch)
            if n >= cap:
                break
    except Exception:
        pass
    raw = b"".join(chunks)
    declared = "charset" in (r.headers.get("Content-Type") or "").lower()
    m = re.search(rb'<meta[^>]+charset=["\']?\s*([a-zA-Z0-9_\-]+)', raw[:4096])
    for enc in ([r.encoding] if declared and r.encoding else []) + ([m.group(1).decode("ascii", "ignore")] if m else []) + ["utf-8"]:
        try:
            return raw.decode(enc)
        except Exception:
            continue
    try:
        return raw.decode(r.apparent_encoding or "cp1252", errors="replace")
    except Exception:
        return raw.decode("utf-8", errors="replace")


def check_row(row, now_iso):
    """Run every part-A check on one merged row. Returns a dict of result columns."""
    out = {c: "" for c in out_cols()}
    out.update({k: row.get(k, "") for k in ("id", "tier", "priority", "site_url", "access_url")})
    for k in RAW_COLS:
        out[k] = row.get(k, "")
    for c in CHECKS:
        out[c] = "not_checked"
    out["checked_at"] = now_iso

    site = (row.get("site_url") or "").strip()
    access = (row.get("access_url") or "").strip()
    body, parser, text, title, final = "", None, "", "", ""
    live = False

    # ---- landing page
    if not site:
        for c in ("chk_link_live", "chk_redirect", "chk_tls", "chk_soft404", "chk_withdrawn", "chk_machine_metadata", "chk_archived"):
            out[c] = "n.a."; out[c + "_detail"] = "no site_url"
    elif not site.lower().startswith(("http://", "https://")):
        for c in ("chk_link_live", "chk_redirect", "chk_tls", "chk_soft404", "chk_withdrawn", "chk_machine_metadata", "chk_archived"):
            out[c] = "n.a."; out[c + "_detail"] = f"non-http site_url ({site.split(':')[0]})"
    elif not robots_allows(site):
        out["chk_link_live"] = "warn"; out["chk_link_live_detail"] = "blocked_robots: robots.txt disallows this page for our agent"
        for c in ("chk_redirect", "chk_tls", "chk_soft404", "chk_withdrawn", "chk_machine_metadata"):
            out[c] = "not_checked"; out[c + "_detail"] = "blocked_robots"
    else:
        r, err, etxt, ms = polite_request("GET", site, stream=True)
        out["response_ms"] = ms
        if r is None:
            if err == "tls":
                out["chk_tls"] = "fail"; out["chk_tls_detail"] = "certificate error: " + etxt[:200]
                out["chk_link_live"] = "fail"; out["chk_link_live_detail"] = "tls_error (not bypassed)"
            elif err == "redirect_loop":
                out["chk_redirect"] = "fail"; out["chk_redirect_detail"] = "redirect loop: " + etxt[:200]
                out["chk_link_live"] = "fail"; out["chk_link_live_detail"] = "redirect_loop"
            elif err == "dns":
                out["chk_link_live"] = "fail"; out["chk_link_live_detail"] = "dns_failure: " + etxt[:200]
            elif err == "timeout":
                out["chk_link_live"] = "warn"; out["chk_link_live_detail"] = "timeout after retry (20 s x2)"
            elif err == "invalid_url":
                out["chk_link_live"] = "fail"; out["chk_link_live_detail"] = "invalid_url: " + etxt[:200]
            else:
                out["chk_link_live"] = "warn"; out["chk_link_live_detail"] = f"{err}: {etxt[:200]}"
            for c in ("chk_soft404", "chk_withdrawn", "chk_machine_metadata"):
                out[c] = "n.a."; out[c + "_detail"] = "page not fetched"
            if out["chk_redirect"] == "not_checked":
                out["chk_redirect"] = "n.a."; out["chk_redirect_detail"] = "page not fetched"
            if out["chk_tls"] == "not_checked":
                out["chk_tls"] = "n.a."; out["chk_tls_detail"] = "page not fetched"
        else:
            try:
                st = r.status_code
                final = r.url
                ctype = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
                out["http_status"] = st; out["final_url"] = final; out["content_type"] = ctype
                # tls
                if final.lower().startswith("https://"):
                    out["chk_tls"] = "pass"; out["chk_tls_detail"] = "valid certificate"
                else:
                    out["chk_tls"] = "n.a."; out["chk_tls_detail"] = "plain http"
                # redirect
                rd_from, rd_to = registered_domain(domain_of(site)), registered_domain(domain_of(final))
                if not r.history:
                    out["chk_redirect"] = "pass"; out["chk_redirect_detail"] = "no redirect"
                elif rd_from in ("doi.org", "handle.net", "purl.org", "w3id.org", "identifiers.org"):
                    out["chk_redirect"] = "pass"; out["chk_redirect_detail"] = f"persistent-id resolver redirect to {rd_to}: {final}"
                elif rd_from == rd_to:
                    out["chk_redirect"] = "pass"; out["chk_redirect_detail"] = f"{len(r.history)} redirect(s) within {rd_to}"
                else:
                    out["chk_redirect"] = "warn"; out["chk_redirect_detail"] = f"moved to {rd_to}: {final}"
                # live
                if is_bot_block(r):
                    out["chk_link_live"] = "warn"; out["chk_link_live_detail"] = f"blocked_bot: HTTP {st}" + (" (challenge page, empty body)" if st == 202 else "")
                elif 200 <= st < 300:
                    live = True
                    out["chk_link_live"] = "pass"; out["chk_link_live_detail"] = f"HTTP {st}"
                elif st in (404, 410) or st >= 500:
                    out["chk_link_live"] = "fail"; out["chk_link_live_detail"] = f"HTTP {st}"
                else:
                    out["chk_link_live"] = "warn"; out["chk_link_live_detail"] = f"HTTP {st}"
                # body (landing pages may be read in full; never read a binary payload)
                textual = any(x in ctype for x in ("html", "json", "xml", "text/plain", "ld+json"))
                if textual or not ctype:
                    body = read_capped(r)
                    if "html" in ctype or (not ctype and "<html" in body[:5000].lower()):
                        parser, text = parse_html(body)
                        title = re.sub(r"\s+", " ", htmlmod.unescape(parser.title)).strip()
                    else:
                        text = body
                        try:
                            if "json" in ctype:
                                j = json.loads(body[:2000000]); title = str(j.get("title") or j.get("name") or "") if isinstance(j, dict) else ""
                        except Exception:
                            pass
                else:
                    out["chk_soft404"] = "n.a."; out["chk_soft404_detail"] = f"binary response ({ctype}); body not read"
                    out["chk_withdrawn"] = "n.a."; out["chk_withdrawn_detail"] = f"binary response ({ctype})"
                    out["chk_machine_metadata"] = "n.a."; out["chk_machine_metadata_detail"] = f"binary response ({ctype})"
                out["page_title"] = title[:200]
            finally:
                r.close()
            if live and "cmr.earthdata.nasa.gov" in domain_of(final) and final.endswith(".html"):
                # the CMR HTML page is rendered client-side; the same concept's UMM-JSON holds the record
                cr, cerr, _, _ = polite_request("GET", final[:-5] + ".umm_json")
                if cr is not None:
                    try:
                        if cr.status_code == 200:
                            cj = cr.json(); title = cj.get("EntryTitle") or title; text = json.dumps(cj)[:400000]
                            out["page_title"] = title[:200]; out["content_type"] += " (+umm_json)"
                    except Exception:
                        pass
                    finally:
                        cr.close()

            if is_bot_block(r) and not live:
                for c in ("chk_soft404", "chk_withdrawn", "chk_machine_metadata"):
                    out[c] = "not_checked"; out[c + "_detail"] = "blocked_bot"
            elif not live:
                for c in ("chk_soft404", "chk_withdrawn", "chk_machine_metadata"):
                    if out[c] == "not_checked":
                        out[c] = "n.a."; out[c + "_detail"] = f"page not live (HTTP {out['http_status']})"
            elif out["chk_soft404"] == "not_checked":
                # soft-404
                toks = sig_tokens(row.get("dataset_name"))
                hay = (title + " " + text[:400000]).lower()
                hits = [t for t in toks if t in hay]
                frac = len(hits) / len(toks) if toks else 0
                org_toks = sig_tokens(row.get("organization"))
                org_hit = bool(org_toks) and sum(1 for t in org_toks if t in hay) / len(org_toks) >= 0.5
                p0, p1 = urlsplit(site).path.rstrip("/"), urlsplit(final).path.rstrip("/")
                generic = bool(GENERIC_TITLE.search(title)) or (p0 and not p1) or ("/search" in p1 and "/search" not in p0) or \
                          (("/login" in p1 or "/signin" in p1 or "/auth" in p1) and "/login" not in p0)
                js_shell = parser is not None and len(text) < 400 and (parser.scripts_src or "<script" in body[:200000].lower()) and frac < 0.5
                if js_shell and not generic:
                    out["chk_soft404"] = "warn"; out["chk_soft404_detail"] = f"JS-rendered shell ({len(text)} chars of text); name tokens {len(hits)}/{len(toks)}; title \"{title[:80]}\"; needs browser or part B"
                elif generic and frac < 0.5:
                    why = "generic title" if GENERIC_TITLE.search(title) else "redirected to home/search/login"
                    out["chk_soft404"] = "fail"; out["chk_soft404_detail"] = f"{why}: \"{title[:80]}\" -> {final}; name tokens {len(hits)}/{len(toks)}"
                elif frac >= 0.5:
                    out["chk_soft404"] = "pass"; out["chk_soft404_detail"] = f"name tokens {len(hits)}/{len(toks)}; title \"{title[:80]}\""
                elif org_hit:
                    out["chk_soft404"] = "pass"; out["chk_soft404_detail"] = f"publisher named; name tokens {len(hits)}/{len(toks)}; title \"{title[:80]}\""
                else:
                    out["chk_soft404"] = "warn"; out["chk_soft404_detail"] = f"weak match: name tokens {len(hits)}/{len(toks)}; title \"{title[:80]}\""
                # withdrawn
                w = find_withdrawn(title, text[:400000])
                if w:
                    out["chk_withdrawn"] = "fail"; out["chk_withdrawn_detail"] = w[:300]
                elif js_shell:
                    out["chk_withdrawn"] = "not_checked"; out["chk_withdrawn_detail"] = "JS-rendered shell; no server-side text to read"
                else:
                    out["chk_withdrawn"] = "pass"; out["chk_withdrawn_detail"] = "no withdrawal language"
                # machine metadata
                res, kind, det = detect_metadata(site, final, ctype, body, parser)
                if res == "fail" and js_shell:
                    det += " (JS-rendered shell; the served HTML has no embedded metadata)"
                out["chk_machine_metadata"] = res; out["chk_machine_metadata_detail"] = det; out["metadata_kind"] = kind

    # persistent id (URL-based evidence counts even when the page is blocked)
    res, pid, det = find_pid(site, access, text if live else "", parser if live else None)
    if not live and res == "warn" and site:
        res = "not_checked"; det = "no DOI in URLs; page not read"
    out["chk_persistent_id"] = res; out["chk_persistent_id_detail"] = det; out["persistent_id"] = pid

    # ---- access_url
    if not access:
        out["chk_access_url"] = "n.a."; out["chk_access_url_detail"] = "no access_url"
        out["chk_format_match"] = "n.a."; out["chk_format_match_detail"] = "no access_url"
    elif not access.lower().startswith(("http://", "https://")):
        out["chk_access_url"] = "n.a."; out["chk_access_url_detail"] = f"non-http scheme ({access.split(':')[0]}); not probed"
        out["chk_format_match"] = "n.a."; out["chk_format_match_detail"] = "non-http access_url"
    else:
        r, err, etxt, ms = polite_request("HEAD", access)
        if r is not None and r.status_code in (405, 501, 400, 403, 404) or (r is None and err not in ("dns", "tls", "redirect_loop", "invalid_url")):
            # fall back to a 1 KB range GET (many servers reject HEAD or answer it differently)
            if r is not None:
                r.close()
            r2, err2, etxt2, ms2 = polite_request("GET", access, headers={"Range": "bytes=0-1023"}, stream=True)
            if r2 is not None:
                r, err, etxt, ms = r2, err2, etxt2, ms2
            elif r is None:
                err, etxt = err2, etxt2
        act = ""
        if r is None:
            m = {"tls": ("fail", "certificate error (not bypassed): " + etxt[:150]), "dns": ("fail", "dns_failure"),
                 "redirect_loop": ("fail", "redirect loop"), "timeout": ("warn", "timeout after retry"),
                 "invalid_url": ("fail", "invalid_url: " + etxt[:150])}
            res, det = m.get(err, ("warn", f"{err}: {etxt[:150]}"))
            out["chk_access_url"] = res; out["chk_access_url_detail"] = det
            out["chk_format_match"] = "n.a."; out["chk_format_match_detail"] = "endpoint not reached"
        else:
            try:
                st = r.status_code
                act = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
                out["access_http_status"] = st; out["access_final_url"] = r.url; out["access_content_type"] = act
            finally:
                r.close()
            if 200 <= st < 300:
                out["chk_access_url"] = "pass"; out["chk_access_url_detail"] = f"HTTP {st} ({act or 'no content-type'})"
            elif st in (401, 403):
                out["chk_access_url"] = "warn"; out["chk_access_url_detail"] = f"HTTP {st}: needs login, key or is bot-protected"
            elif st == 429:
                out["chk_access_url"] = "warn"; out["chk_access_url_detail"] = "HTTP 429: rate limited"
            elif st in (404, 410) or st >= 500:
                out["chk_access_url"] = "fail"; out["chk_access_url_detail"] = f"HTTP {st}"
            else:
                out["chk_access_url"] = "warn"; out["chk_access_url_detail"] = f"HTTP {st}"
            if out["chk_access_url"] == "pass":
                res, det = format_match(row.get("format"), act, r.url)
                out["chk_format_match"] = res; out["chk_format_match_detail"] = det
            else:
                out["chk_format_match"] = "n.a."; out["chk_format_match_detail"] = f"endpoint not 2xx (HTTP {st})"

    # ---- wayback (CDX API on web.archive.org; the archive.org/wayback/available API answered 429 to every request on 2026-10-21)
    if site and site.lower().startswith(("http://", "https://")):
        cdx = "https://web.archive.org/cdx/search/cdx?output=json&limit=-1&fl=timestamp,statuscode&url=" + quote(site, safe="")
        wr, werr, wtxt, _ = polite_request("GET", cdx)
        if wr is None:
            out["chk_archived"] = "not_checked"; out["chk_archived_detail"] = f"wayback cdx api {werr}"
        else:
            rows_ = []
            try:
                if wr.status_code == 200 and wr.text.strip():
                    rows_ = json.loads(wr.text)
            except Exception:
                rows_ = []
            finally:
                wr.close()
            snap = rows_[1] if len(rows_) >= 2 and isinstance(rows_[1], list) and rows_[1] else None
            if snap:
                ts, sc = str(snap[0]), str(snap[1]) if len(snap) > 1 else ""
                d = f"{ts[:4]}-{ts[4:6]}-{ts[6:8]}"
                out["wayback_url"] = f"https://web.archive.org/web/{ts}/{site}"; out["wayback_date"] = d
                age_ok = datetime.strptime(d, "%Y-%m-%d") >= datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=730)
                out["chk_archived"] = "pass" if age_ok else "warn"
                out["chk_archived_detail"] = f"latest snapshot {d} (archived status {sc})" + ("" if age_ok else "; older than 2 years")
            elif wr.status_code != 200:
                out["chk_archived"] = "not_checked"; out["chk_archived_detail"] = f"wayback cdx api HTTP {wr.status_code}"
            else:
                out["chk_archived"] = "fail"; out["chk_archived_detail"] = "no Wayback snapshot"

    summarise(out)
    return out


def summarise(out):
    res = {c: out[c] for c in CHECKS}
    app = [c for c in CHECKS if res[c] in ("pass", "warn", "fail")]
    out["checks_applicable"] = len(app)
    out["checks_passed"] = sum(1 for c in app if res[c] == "pass")
    out["checks_warned"] = sum(1 for c in app if res[c] == "warn")
    out["checks_failed"] = sum(1 for c in app if res[c] == "fail")
    out["all_passing_A"] = "TRUE" if app and out["checks_passed"] == len(app) else "FALSE"
    ll, lld = res["chk_link_live"], out["chk_link_live_detail"]
    if ll == "n.a.":
        out["url_health"] = "n.a."
    elif ll == "fail" or res["chk_withdrawn"] == "fail" or res["chk_soft404"] == "fail":
        out["url_health"] = "dead"
    elif ll == "warn" and ("blocked_bot" in lld or "blocked_robots" in lld):
        out["url_health"] = "blocked"
    elif ll == "warn":
        out["url_health"] = "blocked" if "timeout" in lld else "degraded"
    elif res["chk_redirect"] == "warn":
        out["url_health"] = "moved"
    elif res["chk_soft404"] == "warn" or res["chk_access_url"] == "fail" or res["chk_machine_metadata"] == "fail":
        out["url_health"] = "degraded"
    else:
        out["url_health"] = "healthy"


# ----------------------------------------------------------------------------- inputs
def load_rows_csv(path):
    rows = []
    for r in csv.DictReader(open(path, encoding="utf-8")):
        m = {k: "" for k in ["id", "site_url", "access_url", "tier", "priority"] + RAW_COLS}
        m.update({k: (v or "") for k, v in r.items() if k in m})
        rows.append(m)
    return rows


def load_rows(date):
    W = {r["id"]: r for r in csv.DictReader(open(os.path.join(DISC, "inventory-working.csv"), encoding="utf-8"))}
    L = {r["id"]: r for r in csv.DictReader(open(os.path.join(DISC, "leads-2026-10-20.csv"), encoding="utf-8"))}
    wb = openpyxl.load_workbook(os.path.join(DISC, f"place-data-inventory-{date}.xlsx"), read_only=True)
    ws = wb["Inventory"]
    it = ws.iter_rows(values_only=True)
    hdr = [str(h) for h in next(it)]
    col = {h: i for i, h in enumerate(hdr)}
    pick = {"tier": "Tier", "priority": "Priority", "finest_unit": "Finest unit", "unit_basis": "Unit basis", "unit_confidence": "Unit confidence",
            "unit_evidence": "Unit evidence", "gaia_fit": "Gaia fit", "record_type": "Record type", "in_gaia": "In gaiaCatalog (folders)",
            "score_note": "Scoring note", "theme": "Theme"}
    hr_col = [h for h in hdr if h.startswith("Health relevance")][0]
    rows = []
    for rec in it:
        if not rec or rec[col["ID"]] is None:
            continue
        rid = str(rec[col["ID"]])
        base = dict(W.get(rid) or L.get(rid) or {})
        if not base:
            print(f"WARNING: {rid} not in working or leads csv", file=sys.stderr)
            base = {"id": rid, "dataset_name": rec[col["Dataset"]], "site_url": rec[col["Landing page"]] or ""}
        m = {k: "" for k in ["id", "site_url", "access_url"] + RAW_COLS}
        m.update({k: (v or "") for k, v in base.items()})
        for k, h in pick.items():
            v = rec[col[h]]
            if v is not None and str(v) != "":
                m[k] = str(v)
        v = rec[col[hr_col]]
        m["health_relevance"] = "" if v is None else str(v)
        m["tier"] = m.get("tier") or ""
        m["priority"] = m.get("priority") or ""
        rows.append(m)
    return rows


# ----------------------------------------------------------------------------- io
def read_csv(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path, rows, cols):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({c: ("" if r.get(c) is None else r.get(c)) for c in cols})
    os.replace(tmp, path)


LOG_COLS = ["row_id", "check", "result", "detail", "evidence_url", "http_status", "checked_at", "run_id"]


def append_log(path, done_rows, run_id):
    new = not os.path.exists(path)
    with open(path, "a", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=LOG_COLS)
        if new:
            w.writeheader()
        for r in done_rows:
            for c in CHECKS:
                if c in ("chk_access_url", "chk_format_match"):
                    ev, hs = r.get("access_final_url") or r.get("access_url"), r.get("access_http_status")
                elif c == "chk_archived":
                    ev, hs = r.get("wayback_url"), ""
                else:
                    ev, hs = r.get("final_url") or r.get("site_url"), r.get("http_status")
                w.writerow({"row_id": r["id"], "check": c, "result": r[c], "detail": (r.get(c + "_detail") or "")[:300],
                            "evidence_url": ev or "", "http_status": hs or "", "checked_at": r["checked_at"], "run_id": run_id})


# ----------------------------------------------------------------------------- run
def run(args):
    date = args.date
    out_csv = os.path.join(OUT, f"verify-A-{date}.csv")
    log_csv = os.path.join(OUT, "verify-log.csv")
    rows = load_rows_csv(args.rows_csv) if args.rows_csv else load_rows(date)
    if args.ids:
        want = set(args.ids.split(","))
        rows = [r for r in rows if r["id"] in want]
    if args.limit:
        rows = rows[:args.limit]
    order = {r["id"]: i for i, r in enumerate(rows)}
    done = {r["id"]: r for r in read_csv(out_csv)}
    run_id = args.run_id or f"A-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
    if args.redo_ids:
        redo = set(args.redo_ids.split(","))
        for rid in redo:
            done.pop(rid, None)
        if args.run_id:
            # same run id: the earlier results were defective, replace them in the log too
            log = read_csv(log_csv)
            kept = [r for r in log if not (r["row_id"] in redo and r["run_id"] == run_id)]
            if len(kept) != len(log):
                write_csv(log_csv, kept, LOG_COLS)
                print(f"redo: dropped {len(log)-len(kept)} log entries for {len(redo)} rows in {run_id}", file=sys.stderr)
        else:
            print(f"redo: {len(redo)} rows re-checked under new run_id {run_id}; earlier results stay in the log", file=sys.stderr)
    todo = [r for r in rows if r["id"] not in done]
    print(f"{len(rows)} rows in scope; {len(done)} already done; {len(todo)} to check; run_id {run_id}; workers {args.workers}", file=sys.stderr)
    t_start = time.monotonic()

    # group by landing domain so each domain is served serially by one thread
    groups = defaultdict(list)
    for r in todo:
        groups[domain_of(r["site_url"]) or "_none"].append(r)
    glist = sorted(groups.values(), key=len, reverse=True)
    q, qlock = [], threading.Lock()
    counter = {"n": 0}

    def work(group):
        for r in group:
            try:
                res = check_row(r, datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
            except Exception as e:  # never lose a row to a bug
                res = {c: "" for c in out_cols()}
                res.update({k: r.get(k, "") for k in ("id", "tier", "priority", "site_url", "access_url")})
                for k in RAW_COLS:
                    res[k] = r.get(k, "")
                for c in CHECKS:
                    res[c] = "not_checked"; res[c + "_detail"] = f"script error: {type(e).__name__}: {str(e)[:120]}"
                res["checked_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                summarise(res)
            with qlock:
                q.append(res)

    pending_log = []

    def checkpoint(final=False):
        nonlocal pending_log
        with qlock:
            fresh, q[:] = list(q), []
        if not fresh and not final:
            return
        for r in fresh:
            done[r["id"]] = r
        pending_log += fresh
        if len(pending_log) >= CHECKPOINT_EVERY or final:
            ordered = sorted(done.values(), key=lambda r: order.get(r["id"], 10**6))
            write_csv(out_csv, ordered, out_cols())
            append_log(log_csv, pending_log, run_id)
            counter["n"] += len(pending_log)
            el = time.monotonic() - t_start
            print(f"  checkpoint: {len(done)}/{len(rows)} rows written, {counter['n']} new this run, {el/60:.1f} min elapsed", file=sys.stderr)
            pending_log = []

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(work, g) for g in glist]
        while any(not f.done() for f in futs):
            time.sleep(2)
            checkpoint()
        for f in futs:
            f.result()
    checkpoint(final=True)
    elapsed = time.monotonic() - t_start
    print(f"done: {len(done)} rows, {elapsed/60:.1f} min this run", file=sys.stderr)
    return out_csv, log_csv, run_id, elapsed


def browser_queue(date):
    rows = read_csv(os.path.join(OUT, f"verify-A-{date}.csv"))
    cols = ["id", "tier", "priority", "dataset_name", "organization", "theme", "site_url", "access_url", "reason", "http_status", "what_to_confirm"]
    out = []
    for r in rows:
        if not r.get("priority"):
            continue
        d = r.get("chk_link_live_detail") or ""
        reason = "blocked_bot" if "blocked_bot" in d else "blocked_robots" if "blocked_robots" in d else ""
        if not reason:
            continue
        out.append({**{c: r.get(c, "") for c in cols}, "reason": reason,
                    "what_to_confirm": "page loads and names this dataset; not retired; licence; years covered; finest spatial unit; download format and access route"})
    path = os.path.join(OUT, f"browser-queue-{date}.csv")
    write_csv(path, out, cols)
    return path, len(out)


def changes(date, log_csv, run_id):
    log = read_csv(log_csv)
    runs = sorted({r["run_id"] for r in log})
    prev = [x for x in runs if x < run_id]
    if not prev:
        return None
    prev = prev[-1]
    cur = {(r["row_id"], r["check"]): r for r in log if r["run_id"] == run_id}
    old = {(r["row_id"], r["check"]): r for r in log if r["run_id"] == prev}
    lines = [f"# Verification changes: {prev} -> {run_id}", "", "| row | check | before | after | detail |", "|---|---|---|---|---|"]
    n = 0
    for k, r in cur.items():
        o = old.get(k)
        if o and o["result"] != r["result"]:
            lines.append(f"| {k[0]} | {k[1]} | {o['result']} | {r['result']} | {r['detail'][:120].replace('|', '/')} |"); n += 1
        elif o and k[1] == "chk_redirect" and r["result"] == "warn" and o["detail"] != r["detail"]:
            lines.append(f"| {k[0]} | {k[1]} | {o['detail'][:60]} | {r['detail'][:60]} | new redirect target |"); n += 1
    lines.insert(2, f"{n} changed results. Rows: {len({k[0] for k in cur})} in this run, {len({k[0] for k in old})} in the previous one.")
    path = os.path.join(OUT, f"verify-changes-{date}.md")
    open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return path


# ----------------------------------------------------------------------------- report
def report(date, elapsed_s=None, run_id=""):
    rows = read_csv(os.path.join(OUT, f"verify-A-{date}.csv"))
    short = [r for r in rows if r.get("priority")]
    L = []
    L.append(f"# Verification, part A: reachability and URL health ({date})")
    L.append("")
    L.append(f"Scripted run of `scripts/verify_links.py` over {len(rows)} inventory rows ({sum(1 for r in rows if r['tier']=='Curated')} curated, "
             f"{sum(1 for r in rows if r['tier']!='Curated')} inferred-unit leads), of which {len(short)} are shortlist rows. "
             "No pages were read by an agent and no datasets were downloaded. Parts B (content) and C (Gaia readiness) are not done." )
    if run_id:
        L.append(f"Run id `{run_id}`; results also appended to `verify-log.csv`.")
    L.append("")
    L.append("## Results per check")
    L.append("")
    L.append("| Check | pass | warn | fail | n.a. | not_checked |")
    L.append("|---|---|---|---|---|---|")
    for c in CHECKS:
        cnt = Counter(r[c] for r in rows)
        L.append(f"| `{c}` | {cnt.get('pass',0)} | {cnt.get('warn',0)} | {cnt.get('fail',0)} | {cnt.get('n.a.',0)} | {cnt.get('not_checked',0)} |")
    L.append("")
    L.append(f"Rows with every applicable A check passing (`all_passing_A`): {sum(1 for r in rows if r['all_passing_A']=='TRUE')} of {len(rows)} "
             f"({sum(1 for r in short if r['all_passing_A']=='TRUE')} of {len(short)} shortlist rows). "
             "Note that `chk_persistent_id` and `chk_archived` rarely pass for catalog records, so this is a strict bar.")
    L.append("")
    HEALTH = ["healthy", "moved", "degraded", "dead", "blocked", "n.a."]
    L.append("## URL health")
    L.append("")
    L.append("healthy = live, no soft-404, not withdrawn; moved = live but redirected to another registered domain; degraded = live but a soft-404 warning, "
             "a broken access URL or no machine metadata; dead = link fails, or the page is a generic/not-found page, or it says the dataset is withdrawn; "
             "blocked = bot protection (401/403/429, or a 202 challenge page with an empty body), robots.txt disallow, or a timeout after retry.")
    L.append("")
    L.append("| Group | rows | " + " | ".join(HEALTH) + " |")
    L.append("|---|---|" + "---|" * len(HEALTH))

    def hrow(label, rs):
        c = Counter(r["url_health"] for r in rs)
        return f"| {label} | {len(rs)} | " + " | ".join(str(c.get(h, 0)) for h in HEALTH) + " |"
    L.append(hrow("All rows", rows))
    L.append(hrow("Shortlist (priority set)", short))
    L.append(hrow("Shortlist: Verify first (curated)", [r for r in short if r["priority"].startswith("1")]))
    L.append(hrow("Shortlist: Investigate (leads)", [r for r in short if r["priority"].startswith("2")]))
    L.append(hrow("Tier: Curated", [r for r in rows if r["tier"] == "Curated"]))
    L.append(hrow("Tier: Lead (unit inferred)", [r for r in rows if r["tier"] != "Curated"]))
    for th in sorted({r["theme"] for r in rows}):
        L.append(hrow(f"Theme: {th or '(blank)'}", [r for r in rows if r["theme"] == th]))
    L.append("")
    # dead and withdrawn
    dead = [r for r in rows if r["url_health"] == "dead"]
    L.append(f"## Dead and withdrawn datasets ({len(dead)})")
    L.append("")
    L.append("| id | tier | why | HTTP | Wayback snapshot |")
    L.append("|---|---|---|---|---|")
    for r in sorted(dead, key=lambda r: (r["priority"] == "", r["tier"] != "Curated", r["id"])):
        why = []
        if r["chk_link_live"] == "fail": why.append("link: " + r["chk_link_live_detail"][:60])
        if r["chk_withdrawn"] == "fail": why.append("withdrawn: " + r["chk_withdrawn_detail"][:110])
        if r["chk_soft404"] == "fail": why.append("soft-404: " + r["chk_soft404_detail"][:90])
        flag = " **(shortlist)**" if r["priority"] else ""
        L.append(f"| {r['id']}{flag} | {r['tier'][:7]} | {'; '.join(why).replace('|','/')} | {r['http_status']} | {r['wayback_date'] or ('none' if r['chk_archived']=='fail' else 'not checked')} |")
    L.append("")
    # blocked / timeouts by domain
    L.append("## Domains that blocked or timed out")
    L.append("")
    bl = defaultdict(Counter)
    for r in rows:
        d = r["chk_link_live_detail"]
        if r["chk_link_live"] == "warn" and ("blocked" in d or "timeout" in d or "connection" in d):
            kind = "blocked_bot" if "blocked_bot" in d else "blocked_robots" if "blocked_robots" in d else "timeout" if "timeout" in d else "connection error"
            bl[domain_of(r["site_url"])][kind] += 1
    L.append("| domain | rows | kind | shortlist rows |")
    L.append("|---|---|---|---|")
    for dom, c in sorted(bl.items(), key=lambda kv: -sum(kv[1].values())):
        sl = sum(1 for r in short if domain_of(r["site_url"]) == dom and r["chk_link_live"] == "warn" and any(k in r["chk_link_live_detail"] for k in ("blocked", "timeout", "connection")))
        L.append(f"| {dom} | {sum(c.values())} | {', '.join(f'{k} {v}' for k, v in c.items())} | {sl} |")
    acc_bl = Counter(domain_of(r["access_url"]) for r in rows if r["chk_access_url"] == "warn")
    if acc_bl:
        L.append("")
        L.append("Access URLs answering 401/403/429 or timing out (needs login, key, or bot-protected), by domain: " +
                 ", ".join(f"{d} ({n})" for d, n in acc_bl.most_common(15)) + ".")
    L.append("")
    # moved
    mv = defaultdict(set)
    for r in rows:
        if r["chk_redirect"] == "warn":
            mv[registered_domain(domain_of(r["site_url"]))].add(registered_domain(domain_of(r["final_url"])))
    L.append(f"## Domains that moved ({sum(1 for r in rows if r['chk_redirect']=='warn')} rows)")
    L.append("")
    L.append("| from | to | rows |")
    L.append("|---|---|---|")
    for d, tos in sorted(mv.items()):
        n = sum(1 for r in rows if r["chk_redirect"] == "warn" and registered_domain(domain_of(r["site_url"])) == d)
        L.append(f"| {d} | {', '.join(sorted(tos))} | {n} |")
    L.append("")
    # machine metadata
    mm = Counter()
    for r in rows:
        if r["chk_machine_metadata"] == "pass":
            for k in r["metadata_kind"].split("; "):
                mm[k] += 1
    live = sum(1 for r in rows if r["chk_link_live"] == "pass")
    L.append("## Machine-readable metadata")
    L.append("")
    L.append(f"Of {live} live landing pages, {sum(1 for r in rows if r['chk_machine_metadata']=='pass')} expose machine-readable dataset metadata, "
             f"{sum(1 for r in rows if r['chk_machine_metadata']=='warn')} have only OpenGraph or Dublin Core tags, and "
             f"{sum(1 for r in rows if r['chk_machine_metadata']=='fail')} have none that the script recognises. A page can expose more than one kind.")
    L.append("")
    L.append("| kind | pages |")
    L.append("|---|---|")
    for k, n in mm.most_common():
        L.append(f"| {k} | {n} |")
    L.append("")
    pid = Counter(r["chk_persistent_id"] for r in rows)
    L.append(f"Persistent identifiers: {pid.get('pass',0)} rows have a DOI or handle on the page or in a URL "
             f"({sum(1 for r in rows if r['chk_persistent_id']=='pass' and r['chk_persistent_id_detail'].startswith('url'))} in the URL itself). "
             "A DOI found in page text may belong to a cited paper rather than the dataset; part B should confirm.")
    L.append("")
    # run time
    L.append("## Run time and cost")
    L.append("")
    ts = sorted(r["checked_at"] for r in rows if r["checked_at"])
    span = ""
    if ts:
        try:
            t0, t1 = datetime.strptime(ts[0], "%Y-%m-%dT%H:%M:%SZ"), datetime.strptime(ts[-1], "%Y-%m-%dT%H:%M:%SZ")
            span = f"{(t1-t0).total_seconds()/60:.0f} min (first to last row checked, {ts[0]} to {ts[-1]} UTC)"
        except Exception:
            pass
    el = f"{elapsed_s/60:.0f} min" if elapsed_s else ""
    rq = len([r for r in rows if r["site_url"]]) * 2 + len([r for r in rows if r["access_url"]]) + len({domain_of(r["site_url"]) for r in rows})
    L.append(f"- Wall time: {el or span}{'; span of checked_at stamps ' + span if el and span else ''}.")
    L.append(f"- About {rq} HTTP requests (one landing GET, one Wayback CDX lookup and one robots.txt per domain, plus one HEAD or 1 KB range GET per access URL), "
             f"across {len({domain_of(r['site_url']) for r in rows if r['site_url']})} landing domains, at most one request per second per domain.")
    L.append("- Cost: none beyond bandwidth; no LLM calls. The Wayback lookups are the floor (one domain, paced at one request per 2.5 s: about "
             f"{len([r for r in rows if r['site_url']])*2.5/60:.0f} min minimum).")
    L.append(f"- A monthly re-run of all {len(rows)} rows should take about the same wall time ({el or span or 'see above'}); it resumes from the partial CSV if interrupted, "
             "appends a new run_id to `verify-log.csv` and writes `verify-changes-<date>.md` with every result that changed. Re-running only the shortlist "
             f"({len(short)} rows) would take about a quarter of that.")
    L.append("")
    L.append("## Caveats")
    L.append("")
    L.append("- Soft-404 and withdrawal detection are keyword rules on the page text; a `warn` means a person or part B should look, not that the page is wrong.")
    L.append("- `chk_machine_metadata` recognises schema.org Dataset JSON-LD, DCAT markers, CKAN, STAC, CMR, Socrata and ArcGIS Hub pages; other catalog software reads as `fail`.")
    c202 = Counter(domain_of(r["site_url"]) for r in rows if r["http_status"] == "202")
    c5xx = Counter(domain_of(r["site_url"]) for r in rows if r["http_status"][:1] == "5")
    L.append("- Pages behind bot protection (`blocked`) were not retried with other agents or headers; the shortlist ones are in the browser queue. "
             "These domains answer HTTP 202 with an empty body (a JavaScript challenge) to this agent and open normally in a browser: "
             + ", ".join(f"{d} ({n})" for d, n in c202.most_common()) + ". data.gov.au's robots.txt disallows everything for every agent.")
    L.append("- 5xx answers were retried once after 3 s and count as `dead`, but a 500/502/503 can be an outage on the day: "
             + ", ".join(f"{d} ({n})" for d, n in c5xx.most_common()) + ". Rows re-checked with `--redo-ids` keep the later result; the monthly re-run settles the rest.")
    L.append("- TLS failures are what Python's certificate store reported (expired, self-signed, or an incomplete chain). A browser may accept some of them; they were not bypassed.")
    L.append("- Wayback snapshots come from the CDX API on web.archive.org (latest capture of the exact URL), paced at one request per 2.5 s; the availability API answered 429 to every request.")
    L.append("- Access URLs were probed with HEAD, falling back to a 1 KB range GET. Some servers answer HEAD differently from a real download.")
    path = os.path.join(OUT, f"verify-A-report-{date}.md")
    open(path, "w", encoding="utf-8").write("\n".join(L) + "\n")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", required=True, help="workbook / output date, e.g. 2026-10-21")
    ap.add_argument("--workers", type=int, default=12)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--ids", default="")
    ap.add_argument("--run-id", default="", help="reuse a run id (with --redo-ids, or to continue an interrupted run under its id)")
    ap.add_argument("--redo-ids", default="", help="comma-separated ids to re-check under --run-id, replacing their earlier results")
    ap.add_argument("--report-only", action="store_true")
    ap.add_argument("--outdir", default="")
    ap.add_argument("--rows-csv", default="", help="take the rows from this CSV instead of the dated workbook (ad-hoc checks, e.g. mirrors)")
    args = ap.parse_args()
    global OUT
    if args.outdir:
        OUT = os.path.abspath(args.outdir); os.makedirs(OUT, exist_ok=True)
    elapsed = None; run_id = args.run_id
    if not args.report_only:
        _, log_csv, run_id, elapsed = run(args)
        ch = changes(args.date, log_csv, run_id)
        if ch:
            print("changes vs previous run:", ch, file=sys.stderr)
    bq, nbq = browser_queue(args.date)
    print(f"browser queue: {nbq} rows -> {bq}", file=sys.stderr)
    rp = report(args.date, elapsed, run_id)
    print("report:", rp, file=sys.stderr)


if __name__ == "__main__":
    main()
