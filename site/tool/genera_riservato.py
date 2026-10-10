#!/usr/bin/env python3
"""
Genera i dati dell'area riservata del sito: `site/var/riservato/dati.json`.

Si rilancia **ogni volta che si aggiorna `StatusMicroApps.md`** (decisione del proprietario del
2026-10-11, `memory/decisioni.md`), poi si carica con `site/tool/pubblica_riservato.ps1`.

Fonti, tutte nel monorepo (nessuna rete):

- `StatusMicroApps.md`: riepilogo, tabella delle app nuove, legenda, sezioni per app
  (dati, tabelle data/evento, prossimi passi), sezione «Account Google Play».
- `memory/decisioni.md`: le voci `## <data> · <titolo>` con la riga `**Vale per:**`.
- `develop_microapps.md` §1.1 e §1.6: nome, nome di lavoro precedente, fase, problema risolto.
- `site/src/apps.php` e `site/src/lang/it.php`: slug, colore d'accento, claim e sommario delle app
  che hanno gia' una card in vetrina.
- `apps/<app>/README.md`: la prima frase, se il sito non ha ancora un sommario.
- `apps/<app>/flutter_launcher_icons.yaml`: l'icona iOS vera (`image_path`, `background_color_ios`).

Formato di uscita: vedi `site/codebase_reference.md`, sezione «Area riservata», sottosezione
«Il formato di dati.json». Il testo resta in **markdown in linea** (grassetto, codice, barrato,
link): lo trasforma in HTML `src/riservato.php`, dopo averlo ripulito.

Solo libreria standard + Pillow (per ridurre le icone).

    python site/tool/genera_riservato.py            # scrive site/var/riservato/dati.json
    python site/tool/genera_riservato.py --uscita X # altrove (prove)
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import io
import json
import os
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - lo diciamo chiaro invece di uscire senza icone
    Image = None

FORMATO = 1

PALLINI = ['🟢', '🟡', '🔵', '⚪', '🔴', '❌', '🟠']

# ─── Utilita' ────────────────────────────────────────────────────────────────


def leggi(percorso: Path) -> str:
    return percorso.read_text(encoding='utf-8')


def norm(testo: str) -> str:
    """Per i confronti: minuscolo, apostrofi tipografici uniformati, spazi compattati."""
    testo = testo.replace('’', "'").replace('‘', "'").lower()
    return re.sub(r'\s+', ' ', testo).strip()


def celle(riga: str) -> list[str]:
    """Le celle di una riga di tabella markdown, senza i bordi."""
    riga = riga.strip()
    if riga.startswith('|'):
        riga = riga[1:]
    if riga.endswith('|'):
        riga = riga[:-1]
    return [c.strip() for c in riga.split('|')]


def e_separatore(riga: str) -> bool:
    return bool(re.fullmatch(r'\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?', riga.strip()))


def tabelle(testo: str) -> list[list[list[str]]]:
    """Tutte le tabelle di un testo: lista di righe (la prima e' l'intestazione)."""
    out, corrente = [], []
    for riga in testo.splitlines():
        if riga.strip().startswith('|'):
            if not e_separatore(riga):
                corrente.append(celle(riga))
        elif corrente:
            out.append(corrente)
            corrente = []
    if corrente:
        out.append(corrente)
    return out


def sezioni(testo: str, livello: str = '## ') -> list[tuple[str, str]]:
    """Divide un markdown nei titoli di un livello: [(titolo, corpo)]."""
    out: list[tuple[str, str]] = []
    titolo, corpo = None, []
    in_codice = False
    for riga in testo.splitlines():
        if riga.startswith('```'):
            in_codice = not in_codice
        if not in_codice and riga.startswith(livello):
            if titolo is not None:
                out.append((titolo, '\n'.join(corpo)))
            titolo, corpo = riga[len(livello):].strip(), []
        elif titolo is not None:
            corpo.append(riga)
    if titolo is not None:
        out.append((titolo, '\n'.join(corpo)))
    return out


def pallino(testo: str) -> tuple[str | None, str]:
    """Il pallino in testa a una cella (o in un titolo «Google Play — 🟢 pubblicata»)."""
    for p in PALLINI:
        if p in testo:
            return p, testo
    return None, testo


def togli_markdown(testo: str) -> str:
    return re.sub(r'\*\*|~~|`', '', testo)


def breve(cella: str, massimo: int = 46) -> str:
    """
    La cella del riepilogo ridotta a poche parole, come quando il proprietario chiede lo stato
    in chat: «🟢 1.0.1 (12) in vendita», «🔵 test interno», «⚪ non ancora creata».

    Si taglia al primo «;», « — », «: » o alla prima parentesi che non sia un numero di build
    («(12)» resta, «(2026-10-10, …)» no).
    """
    p, _ = pallino(cella)
    testo = cella.replace(p, '', 1) if p else cella
    testo = togli_markdown(testo).strip()
    testo = re.split(r';\s|\s—\s|:\s|\s\((?!\d+\))', testo, maxsplit=1)[0].strip(' ,.')
    if len(testo) > massimo:
        testo = testo[: massimo - 1].rstrip() + '…'
    return testo


def nome_e_ex(cella: str) -> tuple[str, str | None, bool]:
    """«**Boomerang** (ex Te l'ho prestato)» → ('Boomerang', "Te l'ho prestato", annullata?)."""
    annullata = '~~' in cella
    pulito = togli_markdown(cella).strip()
    m = re.match(r'^(.*?)\s*\(ex\s+[«"]?(.+?)[»"]?(?:,.*)?\)\s*$', pulito)
    if m:
        return m.group(1).strip(), m.group(2).strip(), annullata
    return pulito, None, annullata


# ─── Markdown → blocchi ──────────────────────────────────────────────────────


def blocchi(testo: str) -> list[dict]:
    """
    Un pezzo di markdown in blocchi semplici che la pagina PHP sa disegnare:

    - {"tipo": "titolo", "testo": str, "pallino": str|null}
    - {"tipo": "paragrafo", "testo": str}
    - {"tipo": "tabella", "intestazione": [str], "righe": [[str]]}
    - {"tipo": "lista", "ordinata": bool, "voci": [{"testo": str, "spunta": bool|null}]}
    - {"tipo": "nota", "blocchi": [...]}           (i «> » del markdown)
    - {"tipo": "codice", "testo": str}

    Il testo dentro i blocchi resta markdown in linea.
    """
    righe = testo.splitlines()
    out: list[dict] = []
    i = 0
    while i < len(righe):
        riga = righe[i]
        s = riga.strip()
        if not s or s == '---':
            i += 1
            continue
        if s.startswith('```'):
            j = i + 1
            corpo = []
            while j < len(righe) and not righe[j].strip().startswith('```'):
                corpo.append(righe[j])
                j += 1
            out.append({'tipo': 'codice', 'testo': '\n'.join(corpo)})
            i = j + 1
            continue
        if s.startswith('#'):
            t = s.lstrip('#').strip()
            p, _ = pallino(t)
            out.append({'tipo': 'titolo', 'testo': t, 'pallino': p})
            i += 1
            continue
        if s.startswith('>'):
            corpo = []
            while i < len(righe) and righe[i].strip().startswith('>'):
                corpo.append(re.sub(r'^\s*>\s?', '', righe[i]))
                i += 1
            out.append({'tipo': 'nota', 'blocchi': blocchi('\n'.join(corpo))})
            continue
        if s.startswith('|'):
            tab = []
            while i < len(righe) and righe[i].strip().startswith('|'):
                if not e_separatore(righe[i]):
                    tab.append(celle(righe[i]))
                i += 1
            if tab:
                out.append({'tipo': 'tabella', 'intestazione': tab[0], 'righe': tab[1:]})
            continue
        m = re.match(r'^(\s*)([-*]|\d+\.)\s+(.*)$', riga)
        if m:
            ordinata = m.group(2)[0].isdigit()
            voci = []
            while i < len(righe):
                m = re.match(r'^(\s*)([-*]|\d+\.)\s+(.*)$', righe[i])
                if m:
                    t = m.group(3)
                    spunta = None
                    mm = re.match(r'^\[( |x|X)\]\s*(.*)$', t)
                    if mm:
                        spunta = mm.group(1) != ' '
                        t = mm.group(2)
                    voci.append({'testo': t, 'spunta': spunta})
                    i += 1
                elif righe[i].startswith('  ') and righe[i].strip() and voci:
                    voci[-1]['testo'] += ' ' + righe[i].strip()  # continuazione
                    i += 1
                else:
                    break
            out.append({'tipo': 'lista', 'ordinata': ordinata, 'voci': voci})
            continue
        corpo = []
        while i < len(righe):
            s2 = righe[i].strip()
            if (not s2 or s2.startswith(('#', '>', '|', '```')) or s2 == '---'
                    or re.match(r'^([-*]|\d+\.)\s+', s2)):
                break
            corpo.append(s2)
            i += 1
        out.append({'tipo': 'paragrafo', 'testo': ' '.join(corpo)})
    return out


def voci_aperte(bl: list[dict]) -> list[str]:
    """Le caselle non spuntate «- [ ]», anche dentro le note."""
    out = []
    for b in bl:
        if b['tipo'] == 'lista':
            out += [v['testo'] for v in b['voci'] if v['spunta'] is False]
        elif b['tipo'] == 'nota':
            out += voci_aperte(b['blocchi'])
    return out


# ─── Fonti ───────────────────────────────────────────────────────────────────


def catalogo_sito(radice: Path) -> dict[str, dict]:
    """nome → {slug, accento, pubblicata, suPlay, suAppStore} da `site/src/apps.php` (con regex:
    niente PHP da lanciare)."""
    testo = leggi(radice / 'site/src/apps.php')
    out = {}
    for m in re.finditer(r"'([a-z0-9-]+)'\s*=>\s*\[(.*?)\n\s*\],", testo, re.S):
        slug, corpo = m.group(1), m.group(2)
        nome = re.search(r"'nome'\s*=>\s*'([^']*)'", corpo)
        if not nome:
            continue

        def flag(k: str) -> bool:
            f = re.search(rf"'{k}'\s*=>\s*(true|false)", corpo)
            return bool(f and f.group(1) == 'true')

        acc = re.search(r"'accento'\s*=>\s*'(#[0-9A-Fa-f]{6})'", corpo)
        out[nome.group(1)] = {
            'slug': slug,
            'accento': acc.group(1) if acc else None,
            'pubblicata': flag('pubblicata'),
            'suPlay': flag('suPlay'),
            'suAppStore': flag('suAppStore'),
        }
    return out


def stringa_php(chiave: str, testo: str) -> str | None:
    """Il valore di `'chiave' => 'a' . 'b'` in un dizionario PHP (stringhe fra apici singoli)."""
    m = re.search(re.escape(f"'{chiave}'") + r"\s*=>\s*((?:'(?:[^'\\]|\\.)*'\s*\.?\s*)+)", testo)
    if not m:
        return None
    pezzi = re.findall(r"'((?:[^'\\]|\\.)*)'", m.group(1))
    return ''.join(p.replace("\\'", "'").replace('\\\\', '\\') for p in pezzi)


def prima_frase_readme(cartella: Path) -> str | None:
    f = cartella / 'README.md'
    if not f.is_file():
        return None
    for b in blocchi(leggi(f)):
        if b['tipo'] == 'paragrafo':
            return b['testo']
    return None


def icona(cartella: Path) -> str | None:
    """L'icona iOS vera dell'app, 128x128 WebP, come data URI (vedi il perche' nell'atlante)."""
    if Image is None:
        print('! Pillow non installato: niente icone (pip install pillow)', file=sys.stderr)
        return None
    cfg = cartella / 'flutter_launcher_icons.yaml'
    if not cfg.is_file():
        return None
    testo = leggi(cfg)
    m = re.search(r'^\s*image_path:\s*"?([^"\n]+)"?', testo, re.M)
    if not m:
        return None
    sorgente = cartella / m.group(1).strip()
    if not sorgente.is_file():
        return None
    fondo = re.search(r'background_color_ios:\s*"?(#[0-9A-Fa-f]{6})"?', testo)
    im = Image.open(sorgente).convert('RGBA')
    base = Image.new('RGBA', im.size, fondo.group(1) if fondo else '#FFFFFF')
    base.alpha_composite(im)
    piccola = base.convert('RGB').resize((128, 128), Image.LANCZOS)
    buf = io.BytesIO()
    piccola.save(buf, 'WEBP', quality=85, method=6)
    return 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode('ascii')


def iniziale_svg(nome: str, colore: str) -> str:
    """Il segnaposto con l'iniziale, come nelle card «In arrivo» della home, in SVG data URI
    (un attributo `style` sarebbe bloccato dalla CSP `style-src 'self'` del sito)."""
    lettera = (nome.strip()[:1] or '?').upper()
    lettera = lettera.replace('&', '&amp;').replace('<', '&lt;')
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
        f'<rect width="128" height="128" rx="28" fill="{colore}"/>'
        '<text x="64" y="64" dy=".35em" text-anchor="middle" fill="#fff" '
        'font-family="system-ui,Segoe UI,Roboto,Arial,sans-serif" font-size="64" '
        f'font-weight="800">{lettera}</text></svg>'
    )
    return 'data:image/svg+xml;base64,' + base64.b64encode(svg.encode('utf-8')).decode('ascii')


def decisioni(radice: Path) -> list[dict]:
    out = []
    for titolo, corpo in sezioni(leggi(radice / 'memory/decisioni.md')):
        m = re.match(r'^(\d{4}-\d{2}-\d{2})(\s*\([^)]*\))?\s*·\s*(.+)$', titolo)
        if not m:
            continue
        vale = re.search(r'^\*\*Vale per:\*\*\s*(.+)$', corpo, re.M)
        corpo_senza = re.sub(r'^\*\*Vale per:\*\*.*$', '', corpo, flags=re.M)
        bl = blocchi(corpo_senza)
        sintesi = next((b['testo'] for b in bl if b['tipo'] == 'paragrafo'), '')
        out.append({
            'data': m.group(1),
            'quando': (m.group(1) + (m.group(2) or '')).strip(),
            'titolo': m.group(3).strip(),
            'vale_per': vale.group(1).strip() if vale else '',
            'sintesi': sintesi,
            'corpo': bl,
        })
    return out


def decisioni_di(app: dict, tutte: list[dict]) -> list[dict]:
    """Le voci del registro che riguardano un'app: nome, nome di lavoro o fase nel titolo o in
    «Vale per:»."""
    chiavi = [norm(app['nome'])]
    if app.get('ex'):
        chiavi.append(norm(app['ex']))
    out = []
    for d in tutte:
        dove = norm(d['titolo'] + ' ' + d['vale_per'])
        trovata = any(k and k in dove for k in chiavi)
        if not trovata and app.get('fase'):
            trovata = re.search(rf"(?<![–-])\b{re.escape(app['fase'].lower())}\b(?![–-])", dove) is not None
        if trovata:
            out.append({k: d[k] for k in ('data', 'quando', 'titolo', 'vale_per', 'sintesi', 'corpo')})
    return out


def descrizioni_develop(radice: Path) -> tuple[dict, dict]:
    """§1.1 (nome → problema) e §1.6 (fase → {nome, ex, problema, peso})."""
    testo = leggi(radice / 'develop_microapps.md')
    s11 = re.search(r'^### §1\.1.*?(?=^### )', testo, re.M | re.S)
    s16 = re.search(r'^### §1\.6.*?(?=^## )', testo, re.M | re.S)
    per_nome, per_fase = {}, {}
    if s11:
        for tab in tabelle(s11.group(0)):
            if 'App' in tab[0] and 'Problema risolto' in tab[0]:
                ia, ip = tab[0].index('App'), tab[0].index('Problema risolto')
                for r in tab[1:]:
                    per_nome[togli_markdown(r[ia]).strip()] = r[ip]
    if s16:
        for tab in tabelle(s16.group(0)):
            if 'Fase' in tab[0] and 'Problema risolto' in tab[0]:
                ifa, ia, ip = tab[0].index('Fase'), tab[0].index('App'), tab[0].index('Problema risolto')
                ipe = tab[0].index('Cosa pesa davvero') if 'Cosa pesa davvero' in tab[0] else None
                for r in tab[1:]:
                    nome, ex, annullata = nome_e_ex(r[ia])
                    nome = re.sub(r'\s*ANNULLATA.*$', '', nome).strip()
                    per_fase[r[ifa].strip()] = {
                        'nome': nome, 'ex': ex, 'problema': r[ip],
                        'peso': r[ipe] if ipe is not None else None, 'annullata': annullata,
                    }
    return per_nome, per_fase


# ─── Generazione ─────────────────────────────────────────────────────────────


def cella_sito(info: dict | None) -> dict:
    """La colonna «Sito» per le app che non ce l'hanno nel riepilogo: dal catalogo del sito."""
    if info is None:
        return {'pallino': '⚪', 'breve': 'nessuna card', 'completo': 'Non e\' nel catalogo del sito'}
    if info['pubblicata']:
        return {'pallino': '🟢', 'breve': 'pagina online', 'completo': 'Pagina e card accese'}
    return {'pallino': '⚪', 'breve': 'card «In arrivo»', 'completo': 'Card grigia «In arrivo»'}


def cella(testo: str) -> dict:
    p, _ = pallino(testo)
    return {'pallino': p, 'breve': breve(testo), 'completo': testo}


def stato_di(play: str, store: str, annullata: bool) -> str:
    if annullata or '❌' in play + store:
        return 'annullata'
    if '🟢' in play + store:
        return 'pubblicata'
    non_iniziata = all(re.match(r'^\s*⚪\s*non iniziata', c) for c in (play, store))
    return 'non-iniziata' if non_iniziata else 'in-lavorazione'


def genera(radice: Path) -> dict:
    status = leggi(radice / 'StatusMicroApps.md')
    catalogo = catalogo_sito(radice)
    it_php = leggi(radice / 'site/src/lang/it.php')
    per_nome, per_fase = descrizioni_develop(radice)
    tutte_decisioni = decisioni(radice)

    agg = re.search(r'^Ultimo aggiornamento:\s*(.+)$', status, re.M)
    legenda = re.search(r'^Legenda:\s*(.+?)(?:\n\n|\Z)', status, re.M | re.S)

    sez = dict(sezioni(status))
    tabs = tabelle(sez.get('Riepilogo', ''))
    riepilogo = next((t for t in tabs if t[0][:2] == ['App', 'Versione']), [])
    nuove = next((t for t in tabs if t[0][:2] == ['App', 'Fase']), [])

    app: list[dict] = []

    # Le app della tabella principale (le quattro storiche).
    for r in riepilogo[1:]:
        h = riepilogo[0]
        nome = togli_markdown(r[h.index('App')]).strip()
        app.append({
            'nome': nome, 'ex': None, 'fase': None,
            'versione': r[h.index('Versione')],
            'play': r[h.index('Google Play')], 'store': r[h.index('App Store')],
            'sito': r[h.index('Sito: pulsanti')] if 'Sito: pulsanti' in h else None,
            'annullata': False,
        })
    # Le app nuove (F10–F19).
    for r in nuove[1:]:
        h = nuove[0]
        nome, ex, annullata = nome_e_ex(r[h.index('App')])
        fase = r[h.index('Fase')].strip()
        if ex is None and fase in per_fase:
            ex = per_fase[fase]['ex']
        app.append({
            'nome': nome, 'ex': ex, 'fase': fase, 'versione': None,
            'play': r[h.index('Google Play')], 'store': r[h.index('App Store')],
            'sito': None, 'annullata': annullata or per_fase.get(fase, {}).get('annullata', False),
        })

    uscita_app, righe_tabella, in_sospeso = [], [], []
    for a in app:
        info = catalogo.get(a['nome'])
        stato = stato_di(a['play'], a['store'], a['annullata'])
        cartella = radice / 'apps' / a['nome'].lower().replace(' ', '_')
        if not cartella.is_dir():
            cartella = None
        dettaglio = blocchi(sez[a['nome']]) if a['nome'] in sez else []
        aperte = voci_aperte(dettaglio)
        if aperte:
            in_sospeso.append({'app': a['nome'], 'voci': aperte})

        fase_info = per_fase.get(a['fase'] or '', {})
        descrizione = per_nome.get(a['nome']) or fase_info.get('problema')
        claim = sommario = None
        if info:
            claim = stringa_php(f"app.{info['slug']}.claim", it_php)
            sommario = stringa_php(f"app.{info['slug']}.sommario", it_php)
        if not sommario and cartella:
            sommario = prima_frase_readme(cartella)

        img = icona(cartella) if cartella else None
        colore = (info or {}).get('accento') or ('#c9a9a6' if stato == 'annullata' else '#9aa6a0')

        sito = cella(a['sito']) if a['sito'] else cella_sito(info)
        if a['sito'] and not sito['pallino']:
            # «card grigia «In arrivo»» non ha pallino nel riepilogo: lo deduciamo dal catalogo.
            sito['pallino'] = cella_sito(info)['pallino']

        voce = {
            'nome': a['nome'],
            'ex': a['ex'],
            'fase': a['fase'],
            'slug': info['slug'] if info else None,
            'versione': a['versione'],
            'stato': stato,
            'claim': claim,
            'sommario': sommario,
            'descrizione': descrizione,
            'peso': fase_info.get('peso'),
            'icona': img,
            'icona_vera': img is not None,
            'cartella': f"apps/{cartella.name}" if cartella else None,
            'play': cella(a['play']),
            'app_store': cella(a['store']),
            'sito': sito,
            'decisioni': [],
            'dettaglio': dettaglio,
        }
        if not voce['icona']:
            voce['icona'] = iniziale_svg(a['nome'], colore)
        voce['decisioni'] = decisioni_di(voce, tutte_decisioni)
        uscita_app.append(voce)
        if stato in ('pubblicata', 'in-lavorazione'):
            righe_tabella.append(voce['nome'])

    # La sezione comune dell'account Play: i passi non ancora fatti (quelli senza ✅).
    comuni = []
    if 'Account Google Play (comune a tutte le app)' in sez:
        bl = blocchi(sez['Account Google Play (comune a tutte le app)'])
        comuni.append({'titolo': 'Account Google Play (comune a tutte le app)', 'blocchi': bl})
        passi = [v['testo'] for b in bl if b['tipo'] == 'lista' and b['ordinata']
                 for v in b['voci'] if '✅' not in v['testo']]
        if passi:
            in_sospeso.insert(0, {'app': 'Account Google Play', 'voci': passi})

    # Le decisioni che valgono per tutte le app: in una sezione a parte, non ripetute in ognuna.
    generali = [d for d in tutte_decisioni if re.search(r'\btutt[ei]\b', norm(d['vale_per']))]

    return {
        'formato': FORMATO,
        'generato': dt.datetime.now().astimezone().isoformat(timespec='seconds'),
        'aggiornamento_status': togli_markdown(agg.group(1)).strip() if agg else None,
        'legenda': ' '.join(legenda.group(1).split()) if legenda else None,
        'tabella': righe_tabella,
        'in_sospeso': in_sospeso,
        'app': uscita_app,
        'comuni': comuni,
        'decisioni_generali': generali,
    }


def main() -> int:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')  # la console di Windows e' cp1252
    qui = Path(__file__).resolve()
    radice_default = qui.parents[2]  # site/tool/ → monorepo
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--radice', type=Path, default=radice_default, help='radice del monorepo')
    ap.add_argument('--uscita', type=Path, default=radice_default / 'site/var/riservato/dati.json')
    args = ap.parse_args()

    dati = genera(args.radice)
    args.uscita.parent.mkdir(parents=True, exist_ok=True)
    tmp = args.uscita.with_suffix('.tmp')
    tmp.write_text(json.dumps(dati, ensure_ascii=False, indent=1), encoding='utf-8')
    os.replace(tmp, args.uscita)  # chi legge non vede mai un file a meta'

    print(f"Scritto {args.uscita} ({args.uscita.stat().st_size // 1024} KB)")
    print(f"  status del {dati['aggiornamento_status']}")
    print(f"  {len(dati['app'])} app, {len(dati['tabella'])} nella tabella, "
          f"{sum(len(s['voci']) for s in dati['in_sospeso'])} voci in sospeso")
    for a in dati['app']:
        print(f"  - {a['nome']:<16} {a['stato']:<15} icona={'vera' if a['icona_vera'] else 'iniziale':<8} "
              f"decisioni={len(a['decisioni']):<3} sezioni={len(a['dettaglio'])}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
