#!/usr/bin/env python3
"""A4: uso del tema en lib/ (colores, tipografía, espaciado, textos) y
contraste AA calculado de los pares de color del tema.

    python3 tools/experiencia/analisis_tema.py > /tmp/a4.json

Solo lee archivos. Las cifras son por coincidencia de patrones: un
recuento orientativo, no un análisis sintáctico completo.
"""
import json, re, sys, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parents[2]
LIB = ROOT / 'lib'
THEME_FILES = {'lib/app/theme/app_theme.dart', 'lib/app/theme/lux_motion.dart',
               'lib/features/home/presentation/pages/home_design.dart'}
GRID = {0, 1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64}  # múltiplos de 4 + 1/2 px de línea
TOKENS_SPACING = {4, 8, 16, 24, 32, 48, 64}

def rel(p): return str(p.relative_to(ROOT))

files = [p for p in LIB.rglob('*.dart') if not p.name.endswith('.g.dart')]
res = {'archivos': len(files), 'colores_sueltos': collections.Counter(), 'colors_material': collections.Counter(),
       'fontsize_sueltos': collections.Counter(), 'fontsize_valores': collections.Counter(),
       'textstyle_sin_tema': collections.Counter(), 'espaciado_fuera_rejilla': collections.Counter(),
       'espaciado_fuera_tokens': collections.Counter(), 'espaciado_valores': collections.Counter(),
       'textos_fijos': collections.Counter(), 'textos_sospechosos': []}

COLOR = re.compile(r'\bColor\(0x[0-9A-Fa-f]{8}\)')
MATCOL = re.compile(r'\bColors\.(?!transparent\b)[a-z][A-Za-z0-9]*')
FONTSIZE = re.compile(r'fontSize:\s*([0-9.]+)')
TEXTSTYLE = re.compile(r'(?<![A-Za-z])TextStyle\(')
NUMS = re.compile(r'(?:EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(([^)]*)\))|(?:SizedBox\((?:height|width):\s*([0-9.]+))')
STR = re.compile(r"""(?:Text|label:|title:|message:|hint(?:Text)?:|tooltip:|semanticLabel:|subtitle:|confirmLabel:)\s*\(?\s*(?:const\s+)?Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'|(?:Text|SelectableText)\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'|(?:label|title|message|hintText|tooltip|subtitle|confirmLabel|semanticLabel|labelText|helperText|errorText):\s*'([^'\\]*(?:\\.[^'\\]*)*)'""")
EN = re.compile(r"\b(the|and|your|please|error|loading|submit|cancel|continue|sign in|log in|login|password|email|retry|ok|success|failed|warning|settings|profile|home|booking|bookings|driver|rider|ride|search|next|back|done|save|delete|edit|add|new|open|close|view|details|select|choose|payment|card)\b", re.I)
PLACEHOLDER = re.compile(r"lorem|ipsum|TODO|FIXME|xxx|placeholder|A new Flutter project|\?\?|^\s*\?\s*$|^\s*$", re.I)

for p in files:
    r = rel(p)
    src = p.read_text(encoding='utf-8')
    # quita comentarios de línea para no contar ejemplos en la documentación
    code = re.sub(r'//.*', '', src)
    if r not in THEME_FILES:
        n = len(COLOR.findall(code))
        if n: res['colores_sueltos'][r] += n
        n = len(MATCOL.findall(code))
        if n: res['colors_material'][r] += n
        for v in FONTSIZE.findall(code):
            res['fontsize_sueltos'][r] += 1; res['fontsize_valores'][v] += 1
        n = len(TEXTSTYLE.findall(code))
        if n: res['textstyle_sin_tema'][r] += n
        for a, b in NUMS.findall(code):
            vals = re.findall(r'(?<![A-Za-z_.])([0-9]+(?:\.[0-9]+)?)(?![0-9A-Za-z_])', a) if a else [b]
            for v in vals:
                f = float(v)
                res['espaciado_valores'][v] += 1
                if f not in GRID: res['espaciado_fuera_rejilla'][r] += 1
                if f not in TOKENS_SPACING and f != 0: res['espaciado_fuera_tokens'][r] += 1
    for m in STR.finditer(code):
        s = next(x for x in m.groups() if x is not None)
        res['textos_fijos'][r] += 1
        line = code[:m.start()].count('\n') + 1
        if PLACEHOLDER.search(s) or (EN.search(s) and not re.search(r'[áéíóúñ¿¡]', s) and len(s.split()) <= 6 and not re.search(r'\b(de|la|el|tu|tus|con|para|sin|en|y|o|un|una|los|las)\b', s, re.I)):
            res['textos_sospechosos'].append({'archivo': r, 'linea': line, 'texto': s})

# Contraste WCAG 2.1 de los pares del tema.
theme = (ROOT / 'lib/app/theme/app_theme.dart').read_text()
tok = {k: int(v, 16) for k, v in re.findall(r'static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\)', theme)}
def lum(argb):
    c = [(argb >> s & 255) / 255 for s in (16, 8, 0)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def blend(fg, bg):
    a = (fg >> 24 & 255) / 255
    ch = [round(((fg >> s & 255) * a + (bg >> s & 255) * (1 - a))) for s in (16, 8, 0)]
    return 0xFF000000 | ch[0] << 16 | ch[1] << 8 | ch[2]
def ratio(fg, bg):
    fg = blend(fg, bg)
    l1, l2 = sorted([lum(fg), lum(bg)], reverse=True)
    return round((l1 + 0.05) / (l2 + 0.05), 2)
fgs = ['ink', 'inkSecondary', 'inkTertiary', 'sapphire', 'sapphireLight', 'error', 'success', 'warning']
bgs = ['bg', 'surface', 'surfaceMuted', 'surfaceDeep', 'sapphireTint']
pares = [{'texto': f, 'fondo': b, 'ratio': ratio(tok[f], tok[b]), 'AA_normal': ratio(tok[f], tok[b]) >= 4.5,
          'AA_grande': ratio(tok[f], tok[b]) >= 3.0} for f in fgs for b in bgs if f in tok and b in tok]
for fill in ['sapphire', 'sapphireLight', 'error', 'success', 'warning', 'ink']:
    r = ratio(tok['onAccent'], tok[fill])
    pares.append({'texto': 'onAccent', 'fondo': fill, 'ratio': r, 'AA_normal': r >= 4.5, 'AA_grande': r >= 3.0})
# Tintes de error/advertencia al 8 % (chips y avisos) sobre blanco.
for f in ['error', 'warning', 'success', 'sapphire']:
    tint = blend((0x14 << 24) | (tok[f] & 0xFFFFFF), tok['surface'])
    r = ratio(tok[f], tint)
    pares.append({'texto': f, 'fondo': f'{f} al 8 % sobre surface', 'ratio': r, 'AA_normal': r >= 4.5, 'AA_grande': r >= 3.0})

def top(c, n=15): return [{'archivo': k, 'n': v} for k, v in c.most_common(n)]
out = {
    'archivos_dart': res['archivos'],
    'totales': {k: sum(res[k].values()) for k in ['colores_sueltos', 'colors_material', 'fontsize_sueltos', 'textstyle_sin_tema',
                                                  'espaciado_fuera_rejilla', 'espaciado_fuera_tokens', 'textos_fijos']},
    'archivos_con': {k: len(res[k]) for k in ['colores_sueltos', 'colors_material', 'fontsize_sueltos', 'textstyle_sin_tema', 'espaciado_fuera_rejilla', 'textos_fijos']},
    'top_colores_sueltos': top(res['colores_sueltos']), 'top_fontsize_sueltos': top(res['fontsize_sueltos']),
    'fontsize_valores': dict(res['fontsize_valores'].most_common()),
    'top_espaciado_fuera_rejilla': top(res['espaciado_fuera_rejilla']),
    'espaciado_valores_fuera_rejilla': {k: v for k, v in res['espaciado_valores'].most_common() if float(k) not in GRID},
    'top_textos_fijos': top(res['textos_fijos']), 'textos_sospechosos': res['textos_sospechosos'],
    'contraste': pares,
}
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
