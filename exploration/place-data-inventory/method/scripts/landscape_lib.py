"""Shared helpers for Prompt 2 (rate-limited GETs, raw gzip saves, checkpoints). Never prints or stores the data.gov key."""
import gzip, json, os, time, urllib.parse
import requests

D = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
UA = "OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)"
_last = {}
S = requests.Session()
S.headers.update({"User-Agent": UA, "Accept": "application/json"})


def _key():
    return open(os.path.join(D, "..", "..", "config", "keys", "api-data-gov.key"), encoding="utf-8").read().strip()


def get(url, params=None, gap=1.1, timeout=60, headers=None, retries=2):
    host = urllib.parse.urlparse(url).netloc
    h = dict(headers or {})
    if host == "api.gsa.gov":
        h["x-api-key"] = _key()
    for i in range(retries + 1):
        w = gap - (time.time() - _last.get(host, 0))
        if w > 0:
            time.sleep(w)
        _last[host] = time.time()
        try:
            r = S.get(url, params=params, headers=h, timeout=timeout)
        except requests.RequestException as e:
            if i == retries:
                return None, str(e)[:200]
            continue
        if r.status_code in (429, 502, 503, 504) and i < retries:
            time.sleep(5 * (i + 1)); continue
        return r, ""
    return None, "retries"


def save_raw(name, obj):
    p = os.path.join(D, "landscape", "raw", name + ".json.gz")
    with gzip.open(p, "wt", encoding="utf-8") as f:
        json.dump(obj, f)
    return p


def ckpt(name, obj=None):
    p = os.path.join(D, "landscape", "checkpoints", name + ".json")
    if obj is None:
        return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None
    json.dump(obj, open(p, "w", encoding="utf-8"))
