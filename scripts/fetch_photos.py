#!/usr/bin/env python3
"""Descarga una foto libre por especie desde Wikipedia / Wikimedia Commons.

Para cada animal de assets/data/animals.json que aun no tenga imagen:
  1. busca la imagen principal del articulo (es.wikipedia y, si falla, en.wikipedia)
     usando el nombre cientifico;
  2. guarda una miniatura en assets/images/<id>.jpg;
  3. anota autor, licencia y origen en assets/data/photos.json.

Solo usa la biblioteca estandar. Se ejecuta en GitHub Actions.
"""
import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

UA = "IbericoDex/0.2 (https://github.com/MerchandisingBIGMAT/pokedex)"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANIMALS = os.path.join(ROOT, "assets", "data", "animals.json")
PHOTOS = os.path.join(ROOT, "assets", "data", "photos.json")
IMAGES = os.path.join(ROOT, "assets", "images")
SKIP_WORDS = ("map", "mapa", "distribution", "distribucion", "range", "area", "status")


def get(url, binary=False, tries=4):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=40) as resp:
                data = resp.read()
            return data if binary else json.loads(data)
        except Exception as exc:  # noqa: BLE001
            wait = 3 * (attempt + 1)
            print(f"    reintento en {wait}s ({exc})", flush=True)
            time.sleep(wait)
    return None


def api(host, **params):
    params.update(format="json", formatversion="2")
    return get(f"https://{host}/w/api.php?" + urllib.parse.urlencode(params))


def page_image(lang, title):
    data = api(
        f"{lang}.wikipedia.org",
        action="query",
        redirects="1",
        prop="pageimages",
        piprop="thumbnail|name",
        pithumbsize="500",
        pilicense="free",
        titles=title,
    )
    if not data:
        return None
    for page in data.get("query", {}).get("pages", []):
        thumb = page.get("thumbnail", {}).get("source")
        name = page.get("pageimage")
        if not thumb or not name:
            continue
        low = name.lower()
        if low.endswith(".svg") or any(w in low for w in SKIP_WORDS):
            continue
        return thumb, name
    return None


def clean(text, limit=90):
    text = re.sub(r"<[^>]+>", "", text or "")
    text = html.unescape(text)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:limit].rstrip() + ("…" if len(text) > limit else "")


def credit(name):
    data = api(
        "commons.wikimedia.org",
        action="query",
        prop="imageinfo",
        iiprop="extmetadata",
        titles=f"File:{name}",
    )
    author, license_name = "", ""
    try:
        meta = data["query"]["pages"][0]["imageinfo"][0]["extmetadata"]
        author = clean(meta.get("Artist", {}).get("value", ""))
        license_name = clean(meta.get("LicenseShortName", {}).get("value", ""), 40)
    except Exception:  # noqa: BLE001
        pass
    return {
        "author": author or "Autor no indicado",
        "license": license_name or "Ver licencia en el origen",
        "source": "https://commons.wikimedia.org/wiki/File:" + urllib.parse.quote(name.replace(" ", "_")),
    }


def main():
    os.makedirs(IMAGES, exist_ok=True)
    with open(ANIMALS, encoding="utf-8") as fh:
        animals = json.load(fh)
    photos = {}
    if os.path.exists(PHOTOS):
        with open(PHOTOS, encoding="utf-8") as fh:
            photos = json.load(fh)

    missing = []
    for animal in animals:
        aid = animal["id"]
        target = os.path.join(IMAGES, f"{aid}.jpg")
        if os.path.exists(target) and aid in photos:
            continue
        print(f"{aid}: {animal['scientificName']}", flush=True)
        found = None
        for lang, title in (
            ("es", animal["scientificName"]),
            ("en", animal["scientificName"]),
            ("es", animal["commonName"]),
        ):
            found = page_image(lang, title)
            if found:
                break
        if not found:
            print("    SIN FOTO", flush=True)
            missing.append(aid)
            continue
        thumb, name = found
        blob = get(thumb, binary=True)
        if not blob or len(blob) < 2000:
            print("    DESCARGA FALLIDA", flush=True)
            missing.append(aid)
            continue
        with open(target, "wb") as fh:
            fh.write(blob)
        photos[aid] = credit(name)
        print(f"    ok: {name}", flush=True)
        time.sleep(0.4)

    with open(PHOTOS, "w", encoding="utf-8") as fh:
        json.dump(photos, fh, ensure_ascii=False, indent=1, sort_keys=True)

    print(f"\nFotos disponibles: {len(photos)} de {len(animals)}")
    if missing:
        print("Sin foto: " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    sys.exit(main())
