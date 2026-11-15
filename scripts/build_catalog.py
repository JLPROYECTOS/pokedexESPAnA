#!/usr/bin/env python3
"""Genera el catalogo de la app (assets/data/catalog.json) y sus fotos.

Fuentes:
  * data/curated.json: fichas escritas a mano (descripcion, curiosidades...).
  * iNaturalist: especies observadas en Espana (grado de investigacion), con
    nombre comun en espanol, familia, estado de conservacion y foto con licencia.
  * Wikipedia en espanol: texto introductorio y, si hace falta, la foto.

Regla: una especie solo entra en el catalogo si tiene foto.
Los identificadores no cambian entre ejecuciones, para no perder los
avistamientos que el usuario ya tiene registrados.

Se ejecuta en GitHub Actions. Usa Pillow si esta instalado (reduce las fotos).
"""
import concurrent.futures
import html
import io
import json
import os
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

CATALOG_VERSION = 1
UA = "IbericoDex/0.3 (https://github.com/MerchandisingBIGMAT/pokedex)"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "data", "curated.json")
PHOTOS = os.path.join(ROOT, "assets", "data", "photos.json")
CATALOG = os.path.join(ROOT, "assets", "data", "catalog.json")
IMAGES = os.path.join(ROOT, "assets", "images")
INAT = "https://api.inaturalist.org/v1"
SPAIN_FALLBACK = 6774

SKIP_WORDS = {"map", "mapa", "distribution", "distribucion", "range", "status"}
LANGS = ("es", "en", "pt", "fr", "de", "ca")
OK_LICENSES = {"cc0", "cc-by", "cc-by-sa", "cc-by-nc", "cc-by-nc-sa", "pd"}
IUCN = {"LC", "NT", "VU", "EN", "CR"}

# Grupos que se piden a iNaturalist: categoria de la app, taxon, minimo de
# observaciones en Espana y tope de especies.
GROUPS = [
    dict(cat="ave", iconic="Aves", min_obs=10, cap=600),
    dict(cat="mamifero", iconic="Mammalia", min_obs=5, cap=160),
    dict(cat="reptil", iconic="Reptilia", min_obs=5, cap=120),
    dict(cat="anfibio", iconic="Amphibia", min_obs=3, cap=60),
    dict(cat="pez", iconic="Actinopterygii", min_obs=5, cap=450),
    dict(cat="pez", taxon="Elasmobranchii", min_obs=3, cap=60),
    dict(cat="invertebrado", iconic="Insecta", min_obs=20, cap=250, need_name=True),
    dict(cat="invertebrado", iconic="Arachnida", min_obs=20, cap=50, need_name=True),
    dict(cat="invertebrado", iconic="Mollusca", min_obs=20, cap=60, need_name=True),
    dict(cat="invertebrado", taxon="Malacostraca", min_obs=20, cap=40, need_name=True),
]

GROUP_WORD = {
    "ave": "Ave",
    "mamifero": "Mamífero",
    "reptil": "Reptil",
    "anfibio": "Anfibio",
    "pez": "Pez",
    "invertebrado": "Invertebrado",
}

# Domesticos y similares que no deben aparecer.
EXCLUDED = {
    "homo sapiens", "felis catus", "canis familiaris", "canis lupus familiaris",
    "bos taurus", "ovis aries", "capra hircus", "equus caballus", "equus asinus",
    "gallus gallus", "gallus gallus domesticus", "sus domesticus", "lama glama",
    "cavia porcellus", "mustela furo", "anser cygnoides", "cairina moschata",
}

# Nombres con los que iNaturalist llama a especies que ya estan en las fichas
# escritas a mano con otro nombre cientifico.
SYNONYMS = {
    "apricaphanius iberus": "aphanius iberus",
    "lutra lutra": "lutra lutra",
    "bubo bubo": "bubo bubo",
}

# Articulos concretos para fichas cuya imagen principal de Wikipedia no sirve.
OVERRIDES = {
    "salmon_atlantico": [("en", "Atlantic salmon"), ("fr", "Saumon atlantique")],
    "sabalo": [("en", "Allis shad"), ("fr", "Grande alose"), ("de", "Maifisch")],
    "gallineta_comun": [("en", "Common moorhen"), ("de", "Teichhuhn")],
    "somormujo_lavanco": [("en", "Great crested grebe"), ("de", "Haubentaucher")],
}


# --------------------------------------------------------------------- red

def get(url, binary=False, tries=4):
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=45) as resp:
                data = resp.read()
            return data if binary else json.loads(data)
        except Exception as exc:  # noqa: BLE001
            wait = 4 * (attempt + 1)
            print(f"    reintento en {wait}s ({exc}) {url[:110]}", flush=True)
            time.sleep(wait)
    return None


def wiki_api(host, **params):
    params.update(format="json", formatversion="2")
    return get(f"https://{host}/w/api.php?" + urllib.parse.urlencode(params))


def inat(path, **params):
    url = f"{INAT}/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = get(url)
    time.sleep(1.1)  # iNaturalist pide no pasar de ~1 peticion por segundo
    return data or {}


# ------------------------------------------------------------------ texto

def norm(text):
    text = unicodedata.normalize("NFD", (text or "").lower())
    return "".join(c for c in text if unicodedata.category(c) != "Mn").strip()


def clean(text, limit=90):
    text = re.sub(r"<[^>]+>", "", text or "")
    text = html.unescape(text)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:limit].rstrip() + ("…" if len(text) > limit else "")


def nice_name(name):
    """'Petirrojo Europeo' -> 'Petirrojo europeo'; respeta 'de Audouin'."""
    words = (name or "").strip().split()
    out = []
    for i, word in enumerate(words):
        prev = words[i - 1].lower() if i else ""
        if i == 0:
            out.append(word[:1].upper() + word[1:])
        elif prev in ("de", "del") and word[:1].isupper() and len(word) > 3:
            out.append(word)
        else:
            out.append(word.lower())
    return " ".join(out)


def trim_extract(text, limit=520):
    text = re.sub(r"\s+", " ", text or "").strip()
    text = re.sub(r"\(\s*[,;]?\s*\)", "", text)
    text = re.sub(r"\s+([,.;])", r"\1", text)
    if len(text) < 60:
        return ""
    if len(text) <= limit:
        return text
    cut = text[:limit]
    dot = cut.rfind(". ")
    if dot > 200:
        return cut[: dot + 1]
    return cut.rsplit(" ", 1)[0] + "…"


def usable_image_name(name):
    low = (name or "").lower()
    words = set(re.split(r"[^a-z]+", low))
    return bool(low) and not low.endswith((".svg", ".pdf", ".djvu")) and not (words & SKIP_WORDS)


# -------------------------------------------------------------- wikipedia

def page_image(lang, title):
    data = wiki_api(
        f"{lang}.wikipedia.org", action="query", redirects="1", prop="pageimages",
        piprop="thumbnail|name", pithumbsize="500", pilicense="free", titles=title,
    )
    if not data:
        return None
    for page in data.get("query", {}).get("pages", []):
        thumb = page.get("thumbnail", {}).get("source")
        name = page.get("pageimage")
        if thumb and usable_image_name(name):
            return thumb, name
    return None


def commons_credit(name):
    data = wiki_api(
        "commons.wikimedia.org", action="query", prop="imageinfo",
        iiprop="extmetadata", titles=f"File:{name}",
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
        "origin": "Wikimedia Commons",
    }


def wiki_batch(titles):
    """Texto introductorio e imagen de varios articulos de es.wikipedia."""
    result = {}
    for start in range(0, len(titles), 20):
        chunk = titles[start:start + 20]
        data = wiki_api(
            "es.wikipedia.org", action="query", redirects="1",
            prop="extracts|pageimages", exintro="1", explaintext="1", exlimit="20",
            piprop="thumbnail|name", pithumbsize="500", pilicense="free", pilimit="20",
            titles="|".join(chunk),
        )
        time.sleep(0.3)
        if not data:
            continue
        query = data.get("query", {})
        normalized = {n["from"]: n["to"] for n in query.get("normalized", [])}
        redirects = {r["from"]: r["to"] for r in query.get("redirects", [])}
        pages = {p.get("title"): p for p in query.get("pages", [])}
        for title in chunk:
            final = normalized.get(title, title)
            final = redirects.get(final, final)
            page = pages.get(final)
            if not page or page.get("missing"):
                continue
            result[title] = {
                "extract": trim_extract(page.get("extract", "")),
                "thumb": page.get("thumbnail", {}).get("source"),
                "image": page.get("pageimage"),
            }
        print(f"  wikipedia {min(start + 20, len(titles))}/{len(titles)}", flush=True)
    return result


# ------------------------------------------------------------ iNaturalist

def spain_place_id():
    data = inat("places/autocomplete", q="Spain", per_page=20)
    for place in data.get("results", []):
        if place.get("admin_level") == 0 and norm(place.get("name")) in ("spain", "espana"):
            print(f"Lugar: {place.get('display_name')} (id {place['id']})")
            return place["id"]
    print(f"Lugar: no resuelto, se usa {SPAIN_FALLBACK}")
    return SPAIN_FALLBACK


def taxon_id_by_name(name):
    data = inat("taxa/autocomplete", q=name, per_page=10)
    for taxon in data.get("results", []):
        if taxon.get("name") == name:
            return taxon["id"]
    return None


def species_counts(place, group):
    params = dict(
        place_id=place, quality_grade="research", per_page=500, locale="es",
        preferred_place_id=place, captive="false",
    )
    if group.get("iconic"):
        params["iconic_taxa"] = group["iconic"]
    else:
        tid = taxon_id_by_name(group["taxon"])
        if not tid:
            print(f"  taxon {group['taxon']} no encontrado")
            return []
        params["taxon_id"] = tid
    out, page = [], 1
    while len(out) < group["cap"] and page <= 6:
        data = inat("observations/species_counts", page=page, **params)
        results = data.get("results", [])
        if not results:
            break
        for row in results:
            taxon = row.get("taxon") or {}
            if row.get("count", 0) < group["min_obs"]:
                return out
            if taxon.get("rank") != "species":
                continue
            out.append((row["count"], taxon))
            if len(out) >= group["cap"]:
                break
        if len(results) < 500:
            break
        page += 1
    return out


def taxa_details(ids, place):
    """Familia y estado de conservacion (UICN) de cada taxon."""
    info = {}
    for start in range(0, len(ids), 30):
        chunk = ids[start:start + 30]
        data = inat("taxa/" + ",".join(str(i) for i in chunk), locale="es", preferred_place_id=place)
        for taxon in data.get("results", []):
            family = ""
            for anc in taxon.get("ancestors") or []:
                if anc.get("rank") == "family":
                    family = anc.get("name", "")
            status = "NE"
            statuses = list(taxon.get("conservation_statuses") or [])
            if taxon.get("conservation_status"):
                statuses.append(taxon["conservation_status"])
            for st in statuses:
                code = str(st.get("status") or "").upper()
                authority = str(st.get("authority") or "").lower()
                if code in IUCN and "iucn" in authority and not st.get("place"):
                    status = code
                    break
            info[taxon["id"]] = (family, status)
        print(f"  taxones {min(start + 30, len(ids))}/{len(ids)}", flush=True)
    return info


# ------------------------------------------------------------------ fotos

def save_image(url, target):
    blob = get(url, binary=True, tries=3)
    if not blob or len(blob) < 1500:
        return False
    try:
        from PIL import Image  # type: ignore
    except ImportError:
        with open(target, "wb") as fh:
            fh.write(blob)
        return True
    try:
        image = Image.open(io.BytesIO(blob)).convert("RGB")
        image.thumbnail((480, 480))
        image.save(target, "JPEG", quality=74, optimize=True)
        return True
    except Exception as exc:  # noqa: BLE001
        print(f"    imagen no valida ({exc})")
        return False


def image_path(aid):
    return os.path.join(IMAGES, f"{aid}.jpg")


def download_all(jobs):
    """jobs: lista de (id, url). Descarga en paralelo las que falten."""
    jobs = [(aid, url) for aid, url in jobs if url and not os.path.exists(image_path(aid))]
    if not jobs:
        return
    print(f"Descargando {len(jobs)} fotos…", flush=True)
    done = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        futures = [pool.submit(save_image, url, image_path(aid)) for aid, url in jobs]
        for _ in concurrent.futures.as_completed(futures):
            done += 1
            if done % 100 == 0:
                print(f"  {done}/{len(jobs)}", flush=True)


# -------------------------------------------------------------- catalogo

def inat_photo(taxon):
    photo = taxon.get("default_photo") or {}
    license_code = (photo.get("license_code") or "").lower()
    url = photo.get("medium_url") or photo.get("url")
    if not url or license_code not in OK_LICENSES:
        return None
    return {
        "author": clean(photo.get("attribution", ""), 110) or "Autor no indicado",
        "license": license_code.upper(),
        "source": f"https://www.inaturalist.org/photos/{photo.get('id')}",
        "origin": "iNaturalist",
        "url": url,
    }


def fetch_auto(curated):
    place = spain_place_id()
    known_sci = set()
    for animal in curated:
        sci = animal["scientificName"].lower()
        known_sci.add(sci)
        known_sci.add(" ".join(sci.split()[:2]))
    known_names = {norm(a["commonName"]) for a in curated}

    picked, by_sci = [], {}
    seen_ids = set()
    for group in GROUPS:
        label = group.get("iconic") or group.get("taxon")
        rows = species_counts(place, group)
        kept = 0
        for count, taxon in rows:
            sci = (taxon.get("name") or "").strip()
            low = sci.lower()
            by_sci[low] = taxon
            if not sci or low in EXCLUDED or taxon["id"] in seen_ids:
                continue
            common = nice_name(taxon.get("preferred_common_name") or "")
            if group.get("need_name") and (not common or norm(common) == norm(sci)):
                continue
            if low in known_sci or SYNONYMS.get(low) in known_sci:
                continue
            if common and norm(common) in known_names:
                continue
            seen_ids.add(taxon["id"])
            picked.append(dict(cat=group["cat"], count=count, taxon=taxon, common=common or sci))
            kept += 1
        print(f"{label}: {len(rows)} especies, {kept} nuevas", flush=True)

    details = taxa_details([p["taxon"]["id"] for p in picked], place)
    wiki = wiki_batch([p["taxon"]["name"] for p in picked])

    autos = []
    for item in picked:
        taxon = item["taxon"]
        sci = taxon["name"]
        page = wiki.get(sci, {})
        photo = inat_photo(taxon)
        if not photo and page.get("thumb") and usable_image_name(page.get("image")):
            photo = commons_credit(page["image"])
            photo["url"] = page["thumb"]
        if not photo:
            continue  # sin foto libre: no entra
        family, status = details.get(taxon["id"], ("", "NE"))
        description = page.get("extract") or ""
        from_wiki = bool(description)
        if not description:
            description = f"{GROUP_WORD[item['cat']]}"
            if family:
                description += f" de la familia {family}"
            description += " presente en España."
        autos.append({
            "id": f"inat_{taxon['id']}",
            "source": "auto",
            "commonName": item["common"],
            "scientificName": sci,
            "category": item["cat"],
            "family": family,
            "habitat": "",
            "conservation": status,
            "description": description,
            "textSource": "Wikipedia (CC BY-SA 4.0)" if from_wiki else "",
            "facts": [],
            "keywords": [],
            "photo": photo,
        })
    return autos, by_sci


def curated_photos(curated, by_sci):
    photos = {}
    if os.path.exists(PHOTOS):
        with open(PHOTOS, encoding="utf-8") as fh:
            photos = json.load(fh)
    for animal in curated:
        aid = animal["id"]
        if os.path.exists(image_path(aid)) and aid in photos:
            continue
        print(f"{aid}: buscando foto", flush=True)
        taxon = by_sci.get(animal["scientificName"].lower())
        photo = inat_photo(taxon) if taxon else None
        if photo and save_image(photo.pop("url"), image_path(aid)):
            photos[aid] = photo
            continue
        candidates = list(OVERRIDES.get(aid, []))
        candidates += [(lang, animal["scientificName"]) for lang in LANGS]
        candidates.append(("es", animal["commonName"]))
        for lang, title in candidates:
            found = page_image(lang, title)
            if found and save_image(found[0], image_path(aid)):
                photos[aid] = commons_credit(found[1])
                break
        else:
            print("    SIN FOTO", flush=True)
    with open(PHOTOS, "w", encoding="utf-8") as fh:
        json.dump(photos, fh, ensure_ascii=False, indent=1, sort_keys=True)
    return photos


def main():
    os.makedirs(IMAGES, exist_ok=True)
    with open(CURATED, encoding="utf-8") as fh:
        curated = json.load(fh)

    previous = {}
    if os.path.exists(CATALOG):
        with open(CATALOG, encoding="utf-8") as fh:
            previous = json.load(fh)
    autos = [a for a in previous.get("animals", []) if a.get("source") == "auto"]
    by_sci = {}
    refresh = os.environ.get("REFRESH") == "1"
    if refresh or previous.get("version") != CATALOG_VERSION or not autos:
        print("Consultando iNaturalist y Wikipedia…", flush=True)
        fresh, by_sci = fetch_auto(curated)
        if fresh:
            autos = fresh
        else:
            print("AVISO: no se obtuvo ninguna especie nueva; se conserva lo anterior")
    else:
        print(f"Se reutilizan {len(autos)} especies ya generadas")

    photos = curated_photos(curated, by_sci)
    download_all([(a["id"], a.get("photo", {}).get("url")) for a in autos])

    animals, dropped = [], []
    for animal in curated:
        aid = animal["id"]
        if not os.path.exists(image_path(aid)) or aid not in photos:
            dropped.append(aid)
            continue
        entry = dict(animal)
        entry.pop("number", None)
        entry["source"] = "curated"
        credit = dict(photos[aid])
        credit.setdefault("origin", "Wikimedia Commons")
        entry["photo"] = credit
        animals.append(entry)
    for animal in autos:
        if os.path.exists(image_path(animal["id"])):
            animals.append(animal)
        else:
            dropped.append(animal["id"])

    animals.sort(key=lambda a: norm(a["commonName"]))
    with open(CATALOG, "w", encoding="utf-8") as fh:
        json.dump({"version": CATALOG_VERSION, "animals": animals}, fh, ensure_ascii=False, indent=0)

    counts = {}
    for animal in animals:
        counts[animal["category"]] = counts.get(animal["category"], 0) + 1
    print(f"\nCatalogo: {len(animals)} especies con foto")
    for cat, total in sorted(counts.items()):
        print(f"  {cat}: {total}")
    if dropped:
        print(f"Sin foto (fuera del catalogo): {len(dropped)} -> " + ", ".join(dropped[:40]))
    if len(animals) < len(curated) - 10:
        print("ERROR: catalogo demasiado pequeno")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
