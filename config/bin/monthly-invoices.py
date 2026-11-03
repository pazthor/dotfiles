#!/usr/bin/env python3
"""Monthly invoice log from local files in ~/Documents/Facturas/YYYY-MM.
Reads CFDI XML (issuer, RFC, total, date, UUID) and PDFs (text via pdftotext), writes log.csv per month
and a running ~/Documents/Facturas/facturas-log.csv. Usage: monthly-invoices.py [YYYY-MM] (default: previous month)."""
import csv, os, re, subprocess, sys, zipfile, datetime, xml.etree.ElementTree as ET
BASE = os.path.expanduser("~/Documents/Facturas")
MY_RFC = "PAMJ910503PH0"
today = datetime.date.today()
month = sys.argv[1] if len(sys.argv) > 1 else (today.replace(day=1) - datetime.timedelta(days=1)).strftime("%Y-%m")
d = os.path.join(BASE, month)
if not os.path.isdir(d): print(f"No folder {d}"); sys.exit(0)
# unzip any zip so its XML/PDF get logged
for f in os.listdir(d):
    if f.lower().endswith(".zip"):
        out = os.path.join(d, f[:-4])
        if not os.path.isdir(out):
            try: zipfile.ZipFile(os.path.join(d, f)).extractall(out)
            except Exception: pass
def cfdi(path):
    try:
        r = ET.parse(path).getroot()
        if not r.tag.endswith("Comprobante"): return None
        g = lambda tag: next((e for e in r.iter() if e.tag.endswith(tag)), None)
        em, re_, tfd = g("Emisor"), g("Receptor"), g("TimbreFiscalDigital")
        return dict(date=r.get("Fecha","")[:10], issuer=em.get("Nombre","") if em is not None else "",
                    rfc=em.get("Rfc","") if em is not None else "", receiver_rfc=re_.get("Rfc","") if re_ is not None else "",
                    subtotal=r.get("SubTotal",""), total=r.get("Total",""), currency=r.get("Moneda",""),
                    type=r.get("TipoDeComprobante",""), uuid=tfd.get("UUID","") if tfd is not None else "")
    except Exception: return None
def pdf(path):
    try: t = subprocess.run(["pdftotext","-layout",path,"-"],capture_output=True,text=True,timeout=30).stdout
    except Exception: t = ""
    tot = []
    for line in t.splitlines():
        if re.search(r"(?i)\b(total|importe total|grand total|order total)\b", line) and not re.search(r"(?i)sub ?total", line):
            amts = re.findall(r"\$?\s*([\d,]+\.\d{2})", line)
            if amts: tot.append(amts[-1])
    uuid = re.search(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}", t)
    rfc = re.search(r"\b[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\b", t)
    return dict(total=tot[-1].replace(",","") if tot else "", uuid=uuid.group(0).upper() if uuid else "", rfc=rfc.group(0) if rfc else "")
rows, seen = [], set()
for root, _, files in os.walk(d):
    for f in sorted(files, key=lambda x: (not x.lower().endswith(".xml"), x)):
        p = os.path.join(root, f); ext = f.lower().rsplit(".",1)[-1]
        if f == "log.csv" or ext == "zip": continue
        rel = os.path.relpath(p, BASE)
        mdate = datetime.date.fromtimestamp(os.path.getmtime(p)).isoformat()
        row = dict(month=month, file=rel, kind=ext, date=mdate, issuer="", rfc="", receiver_rfc="", subtotal="", total="", currency="", type="", uuid="", needs_review="", direction="")
        if ext == "xml" and (c := cfdi(p)): row.update(c)
        elif ext == "pdf": row.update({k:v for k,v in pdf(p).items() if v})
        row["direction"] = "issued (income)" if row["rfc"] == MY_RFC and row["receiver_rfc"] != MY_RFC else ("received (expense)" if row["rfc"] else "")
        if row["uuid"] and row["uuid"] in seen: row["needs_review"] = "duplicate of XML"
        elif row["uuid"]: seen.add(row["uuid"])
        if not row["total"]: row["needs_review"] = row["needs_review"] or "no total found"
        rows.append(row)
cols = list(rows[0].keys()) if rows else []
with open(os.path.join(d,"log.csv"),"w",newline="") as fh:
    w = csv.DictWriter(fh, cols); w.writeheader(); w.writerows(rows)
# running log: replace this month's rows
allp = os.path.join(BASE,"facturas-log.csv"); old = []
if os.path.exists(allp):
    with open(allp) as fh: old = [r for r in csv.DictReader(fh) if r.get("month") != month]
with open(allp,"w",newline="") as fh:
    w = csv.DictWriter(fh, cols or ["month"]); w.writeheader(); w.writerows(old + rows)
ok = [r for r in rows if r["total"] and not r["needs_review"].startswith("duplicate")]
inc = sum(float(r["total"]) for r in ok if r["direction"].startswith("issued"))
exp = sum(float(r["total"]) for r in ok if not r["direction"].startswith("issued"))
s = f"income ${inc:,.2f}, expenses ${exp:,.2f}"
print(f"{month}: {len(rows)} files logged, {s}, {sum(1 for r in rows if r['needs_review'] and not r['needs_review'].startswith('duplicate'))} need review -> {d}/log.csv")
try: subprocess.run(["notify-send","Facturas "+month,f"{len(rows)} files, {s}"],timeout=5)
except Exception: pass
