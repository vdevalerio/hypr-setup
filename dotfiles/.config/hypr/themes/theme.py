#!/usr/bin/env python3
"""Temas de cor do sistema: um tema fixo (palettes/*.txt) ou "auto", gerado a partir do wallpaper.

    theme.py list              temas disponíveis: id, nome e amostras de cor
    theme.py set <id>          aplica um tema fixo (ex.: catppuccin-mocha)
    theme.py auto <imagem>     gera e aplica a paleta a partir de uma imagem (quadro do wallpaper)
    theme.py name <id>         nome legível do tema

Grava as cores em: Hyprland (bordas), hyprlock, Waybar, SwayNC, Rofi, kitty, GTK, Qt (qt6ct), btop,
fcitx5 e tela de login. lazygit e yazi usam as cores do terminal (nomes ANSI) e seguem sozinhos. Quem recarrega os apps é o wallpaper.sh (wallpaper.sh theme <id|auto>).

Todos os temas têm as mesmas 26 cores nomeadas (nomes do Catppuccin): "mauve" é o acento
principal (bordas, workspace ativo, seleção), "blue" o segundo tom dos gradientes. Para criar um
tema, copie um arquivo de palettes/ e troque as cores.
"""
import colorsys
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PALETTES = HERE / "palettes"
KEYS = ("rosewater flamingo pink mauve lavender blue sapphire sky teal green yellow peach maroon red "
        "text subtext1 subtext0 overlay2 overlay1 overlay0 surface2 surface1 surface0 base mantle crust").split()
# Cores com significado (erro, ok, aviso…) no modo automático: fixas, do Catppuccin
SEMANTIC = ("teal", "green", "yellow", "peach", "maroon", "red")


# ── Paletas ───────────────────────────────────────────────────────────
def load(tid):
    pal, name = {}, tid
    for line in (PALETTES / f"{tid}.txt").read_text().splitlines():
        if m := re.match(r"#\s*name:\s*(.+)", line):
            name = m.group(1).strip()
        elif line.strip() and not line.startswith("#"):
            k, v = line.split()
            pal[k] = v.lower().lstrip("#")
    missing = [k for k in KEYS if k not in pal]
    if missing:
        sys.exit(f"tema {tid}: faltam cores {missing}")
    return name, pal


def themes():
    return sorted(p.stem for p in PALETTES.glob("*.txt"))


def hexc(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0, min(1, l)), max(0, min(1, s)))
    return f"{round(r * 255):02x}{round(g * 255):02x}{round(b * 255):02x}"


def hue_dist(a, b):
    d = abs(a - b) % 1.0
    return min(d, 1 - d)


def auto(image):
    """Paleta a partir das cores dominantes da imagem (k-means do ImageMagick)."""
    out = subprocess.run(["magick", f"{image}[0]", "-resize", "160x160", "-kmeans", "10",
                          "-format", "%c", "histogram:info:-"],
                         capture_output=True, text=True, check=True).stdout
    clusters = []
    for line in out.splitlines():
        m = re.search(r"^\s*(\d+):.*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count, hx = int(m.group(1)), m.group(2)
        r, g, b = (int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        chroma = s * (1 - abs(2 * l - 1))
        clusters.append({"count": count, "h": h, "l": l, "s": s, "chroma": chroma})
    if not clusters:
        sys.exit("não consegui ler as cores da imagem")
    total = sum(c["count"] for c in clusters)
    for c in clusters:
        c["score"] = c["chroma"] * (c["count"] / total) ** 0.5
    ranked = sorted(clusters, key=lambda c: c["score"], reverse=True)

    # Cor dominante (área, com algum peso para cor): tinge o fundo e é o 2º tom dos gradientes.
    # Acento principal: a cor mais viva que contrasta com a dominante (≥ 40° de matiz, ≥ 2% da
    # imagem) — o rosa da árvore no céu azul, o vermelho do portal na noite… Sem contraste,
    # o acento é a própria dominante.
    dominant = max(clusters, key=lambda c: c["count"] * (0.25 + c["chroma"]))
    hd = dominant["h"]
    contrast = [c for c in clusters if c["chroma"] > 0.08 and c["count"] / total >= 0.02
                and hue_dist(c["h"], hd) >= 40 / 360]
    accent = max(contrast, key=lambda c: c["chroma"] * (c["count"] / total) ** 0.25) if contrast else None
    colorful = [c for c in ranked if c["chroma"] > 0.06]
    if accent:
        h1, h2 = accent["h"], hd
    elif colorful:
        h1, h2 = colorful[0]["h"], colorful[0]["h"] + 50 / 360
    else:          # wallpaper sem cor (cinza/preto e branco): acento discreto no matiz dominante
        h1, h2 = hd, hd + 50 / 360
    # 3º matiz: outra cor da imagem diferente das duas (≥ 30°), senão o acento girado
    h3 = next((c["h"] for c in colorful
               if hue_dist(c["h"], h1) >= 30 / 360 and hue_dist(c["h"], h2) >= 30 / 360), h1 - 50 / 360)

    vivid = accent["chroma"] if accent else (colorful[0]["chroma"] if colorful else 0.0)
    S = max(0.35, min(0.85, 0.35 + vivid * 2.2))     # saturação dos acentos (imagem apagada → acentos discretos)
    bg = max(0.10, min(0.24, 0.10 + vivid * 0.5))    # quanto o fundo puxa o matiz principal

    pal = {
        "mauve":     hexc(h1, S, 0.74),
        "lavender":  hexc(h1, S * 0.8, 0.82),
        "blue":      hexc(h2, S, 0.73),
        "sapphire":  hexc(h2, S * 0.9, 0.66),
        "sky":       hexc(h2, S * 0.8, 0.80),
        "pink":      hexc(h3, S, 0.78),
        "flamingo":  hexc(h3, S * 0.7, 0.84),
        "rosewater": hexc(h3, S * 0.6, 0.90),
        "text":      hexc(hd, bg * 1.2, 0.89),
        "subtext1":  hexc(hd, bg, 0.80),
        "subtext0":  hexc(hd, bg, 0.71),
        "overlay2":  hexc(hd, bg, 0.62),
        "overlay1":  hexc(hd, bg, 0.53),
        "overlay0":  hexc(hd, bg, 0.44),
        "surface2":  hexc(hd, bg, 0.31),
        "surface1":  hexc(hd, bg, 0.24),
        "surface0":  hexc(hd, bg, 0.17),
        "base":      hexc(hd, bg, 0.10),
        "mantle":    hexc(hd, bg, 0.08),
        "crust":     hexc(hd, bg, 0.06),
    }
    _, cat = load("catppuccin-mocha")
    pal.update({k: cat[k] for k in SEMANTIC})
    return pal


# ── Arquivos de saída ─────────────────────────────────────────────────
HEADER = "GERADO AUTOMATICAMENTE por ~/.config/hypr/themes/theme.py — não edite"


def hypr_lua(c):
    rows = "\n".join(f'    {k:<9} = "{c[k]}",' for k in KEYS)
    return f"""-- {HEADER}
local c = {{
{rows}
}}

-- c.rgba(c.mauve, "ee") -> "rgba(cba6f7ee)"
function c.rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return c
"""


def hyprlock(c):
    return f"# {HEADER}\n" + "\n".join(f"${k} = rgb({c[k]})" for k in KEYS) + f"\n$base_alpha = rgba({c['base']}cc)\n"


def gtk_colors(c):
    return f"/* {HEADER} */\n" + "\n".join(f"@define-color {k} #{c[k]};" for k in KEYS) + "\n"


def rofi(c):
    rows = "\n".join(f"    {k}: #{c[k]};" for k in KEYS)
    # Gradiente pronto: o rofi não aceita @cor dentro de linear-gradient()
    return (f"/* {HEADER} */\n* {{\n{rows}\n    base-alpha: #{c['base']}ee;\n"
            f"    accent-gradient: linear-gradient(135, #{c['mauve']}, #{c['blue']});\n}}\n")


def kitty(c):
    return f"""# {HEADER}
foreground              #{c['text']}
background              #{c['base']}
selection_foreground    #{c['base']}
selection_background    #{c['rosewater']}
cursor                  #{c['mauve']}
cursor_text_color       #{c['base']}
url_color               #{c['rosewater']}
active_border_color     #{c['lavender']}
inactive_border_color   #{c['overlay0']}
bell_border_color       #{c['yellow']}
active_tab_foreground   #{c['crust']}
active_tab_background   #{c['mauve']}
inactive_tab_foreground #{c['text']}
inactive_tab_background #{c['mantle']}
tab_bar_background      #{c['crust']}

color0  #{c['surface1']}
color8  #{c['surface2']}
color1  #{c['red']}
color9  #{c['red']}
color2  #{c['green']}
color10 #{c['green']}
color3  #{c['yellow']}
color11 #{c['yellow']}
color4  #{c['blue']}
color12 #{c['blue']}
color5  #{c['mauve']}
color13 #{c['pink']}
color6  #{c['teal']}
color14 #{c['teal']}
color7  #{c['subtext1']}
color15 #{c['subtext0']}
"""


def gtk_css(c):
    return f"""/* {HEADER}. Cores para apps GTK/libadwaita (reabra o app). */
@define-color accent_color #{c['mauve']};
@define-color accent_bg_color #{c['mauve']};
@define-color accent_fg_color #{c['crust']};
@define-color window_bg_color #{c['base']};
@define-color window_fg_color #{c['text']};
@define-color view_bg_color #{c['mantle']};
@define-color view_fg_color #{c['text']};
@define-color headerbar_bg_color #{c['crust']};
@define-color headerbar_fg_color #{c['text']};
@define-color sidebar_bg_color #{c['mantle']};
@define-color sidebar_fg_color #{c['text']};
@define-color card_bg_color #{c['surface0']};
@define-color card_fg_color #{c['text']};
@define-color popover_bg_color #{c['surface0']};
@define-color popover_fg_color #{c['text']};
@define-color dialog_bg_color #{c['surface0']};
@define-color dialog_fg_color #{c['text']};
"""


def qt6ct(c):
    # Ordem dos papéis do QPalette: WindowText Button Light Midlight Dark Mid Text BrightText ButtonText
    # Base Window Shadow Highlight HighlightedText Link LinkVisited AlternateBase NoRole ToolTipBase
    # ToolTipText PlaceholderText Accent
    roles = ("text surface0 surface2 surface1 mantle surface1 text text text mantle base crust mauve crust "
             "blue lavender base base surface0 text overlay1 mauve").split()
    dim = {0: "overlay0", 6: "overlay0", 8: "overlay0", 12: "surface1", 13: "overlay1"}
    row = lambda r: ", ".join(f"#ff{c[k]}" for k in r)
    disabled = [dim.get(i, k) for i, k in enumerate(roles)]
    return (f"# {HEADER}. Cores dos apps Qt (qt6ct; reabra o app).\n[ColorScheme]\n"
            f"active_colors={row(roles)}\ndisabled_colors={row(disabled)}\ninactive_colors={row(roles)}\n")


def btop(c):
    k = lambda key, col: f'theme[{key}]="#{c[col]}"'
    rows = [
        'theme[main_bg]=""',  # vazio = fundo do terminal (transparência do kitty)
        k("main_fg", "text"), k("title", "text"), k("hi_fg", "mauve"),
        k("selected_bg", "surface1"), k("selected_fg", "mauve"), k("inactive_fg", "overlay0"),
        k("graph_text", "subtext0"), k("meter_bg", "surface1"), k("proc_misc", "mauve"),
        k("cpu_box", "mauve"), k("mem_box", "blue"), k("net_box", "lavender"), k("proc_box", "mauve"),
        k("div_line", "surface1"),
        k("temp_start", "green"), k("temp_mid", "yellow"), k("temp_end", "red"),
        k("cpu_start", "blue"), k("cpu_mid", "mauve"), k("cpu_end", "pink"),
        k("free_start", "green"), k("free_mid", "green"), k("free_end", "teal"),
        k("cached_start", "sapphire"), k("cached_mid", "sapphire"), k("cached_end", "blue"),
        k("available_start", "teal"), k("available_mid", "teal"), k("available_end", "green"),
        k("used_start", "yellow"), k("used_mid", "peach"), k("used_end", "red"),
        k("download_start", "blue"), k("download_mid", "mauve"), k("download_end", "pink"),
        k("upload_start", "pink"), k("upload_mid", "mauve"), k("upload_end", "blue"),
        k("process_start", "blue"), k("process_mid", "mauve"), k("process_end", "pink"),
    ]
    return f"# {HEADER}. Tema do btop (reabra o btop).\n" + "\n".join(rows) + "\n"


def fcitx5(c):
    return f"""# {HEADER}. Janela de candidatos do fcitx5 (japonês).
[Metadata]
Name=hypr-setup
Version=1
Author=hypr-setup
Description=Cores do tema atual
ScaleWithDPI=True

[InputPanel]
NormalColor=#{c['text']}
HighlightCandidateColor=#{c['crust']}
HighlightColor=#{c['mauve']}
HighlightBackgroundColor=#{c['surface1']}
Spacing=4
EnableBlur=False
FullWidthHighlight=True

[InputPanel/TextMargin]
Left=9
Right=9
Top=6
Bottom=6

# Fundo e destaque são imagens (fcitx5_images): borda e seleção em gradiente, como o rofi.
# Margin = cantos que não esticam (9-slice); ContentMargin = onde o texto começa.
[InputPanel/Background]
Image=panel.png
Color=#{c['base']}

[InputPanel/Background/Margin]
Left=12
Right=12
Top=12
Bottom=12

[InputPanel/ContentMargin]
Left=3
Right=3
Top=3
Bottom=3

[InputPanel/Highlight]
Image=highlight.png
Color=#{c['mauve']}

[InputPanel/Highlight/Margin]
Left=9
Right=9
Top=6
Bottom=6

[Menu]
NormalColor=#{c['text']}
HighlightCandidateColor=#{c['crust']}
Spacing=2

[Menu/Background]
Color=#{c['base']}
BorderColor=#{c['surface2']}
BorderWidth=1

[Menu/Background/Margin]
Left=2
Right=2
Top=2
Bottom=2

[Menu/Highlight]
Image=highlight.png
Color=#{c['mauve']}

[Menu/Separator]
Color=#{c['surface1']}

[Menu/TextMargin]
Left=8
Right=8
Top=6
Bottom=6
"""


def sddm(c):
    return f"""# {HEADER}. Cores da tela de login (copiadas para o tema do SDDM
# por ~/.config/hypr/scripts/sddm-sync.sh).
[General]
accent=#{c['mauve']}
accent2=#{c['blue']}
text=#{c['text']}
subtext=#{c['subtext0']}
base=#{c['base']}
crust=#{c['crust']}
red=#{c['red']}
yellow=#{c['yellow']}
green=#{c['green']}
"""


OUTPUTS = [
    ("~/.config/hypr/colors.lua", hypr_lua),
    ("~/.config/hypr/hyprlock-colors.conf", hyprlock),
    ("~/.config/waybar/colors.css", gtk_colors),
    ("~/.config/swaync/colors.css", gtk_colors),
    ("~/.config/rofi/colors.rasi", rofi),
    ("~/.config/kitty/colors.conf", kitty),
    ("~/.config/gtk-3.0/gtk.css", gtk_css),
    ("~/.config/gtk-4.0/gtk.css", gtk_css),
    ("~/.config/qt6ct/colors/hypr-setup.conf", qt6ct),
    ("~/.config/btop/themes/hypr-setup.theme", btop),
    ("~/.local/share/fcitx5/themes/hypr-setup/theme.conf", fcitx5),
    ("~/.config/hypr/sddm-colors.conf", sddm),
]


def fcitx5_images(c):
    """Imagens do tema do fcitx5: painel com borda em gradiente e destaque em gradiente (ImageMagick)."""
    d = Path("~/.local/share/fcitx5/themes/hypr-setup").expanduser()
    grad = lambda size, angle: ["(", "-size", size, "-define", f"gradient:angle={angle}",
                                f"gradient:#{c['mauve']}-#{c['blue']}", ")"]
    mask = lambda w, h, r, inset=0: ["(", "-size", f"{w}x{h}", "xc:none", "-fill", "white", "-draw",
                                     f"roundrectangle {inset},{inset} {w-1-inset},{h-1-inset} {r},{r}", ")"]
    try:
        # Painel 64x64: gradiente arredondado (borda) com o fundo por cima, 2px para dentro
        subprocess.run(["magick", *grad("64x64", 135), *mask(64, 64, 10), "-compose", "CopyOpacity", "-composite",
                        "(", "-size", "64x64", "xc:none", "-fill", f"#{c['base']}", "-draw",
                        "roundrectangle 2,2 61,61 8,8", ")", "-compose", "Over", "-composite",
                        str(d / "panel.png")], check=True, capture_output=True)
        # Destaque 40x24: pílula em gradiente horizontal
        subprocess.run(["magick", *grad("40x24", 90), *mask(40, 24, 6), "-compose", "CopyOpacity", "-composite",
                        str(d / "highlight.png")], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        pass  # sem ImageMagick: o fcitx5 usa as cores sólidas (Color=) do theme.conf


def write(pal):
    for out, fn in OUTPUTS:
        dest = Path(out).expanduser()
        dest.parent.mkdir(parents=True, exist_ok=True)
        tmp = dest.with_name(dest.name + ".tmp")
        tmp.write_text(fn(pal))
        tmp.replace(dest)
    fcitx5_images(pal)
    # qt6ct só aceita caminho absoluto para o esquema de cores (o arquivo versionado usa ~)
    conf = Path("~/.config/qt6ct/qt6ct.conf").expanduser()
    if conf.exists():
        scheme = Path("~/.config/qt6ct/colors/hypr-setup.conf").expanduser()
        conf.write_text(re.sub(r"(?m)^color_scheme_path=.*$", f"color_scheme_path={scheme}", conf.read_text()))


def main(argv):
    cmd = argv[1] if len(argv) > 1 else ""
    if cmd == "list":
        for tid in themes():
            name, p = load(tid)
            print(f"{tid}\t{name}\t" + " ".join(p[k] for k in ("mauve", "blue", "pink", "green", "peach")))
    elif cmd == "set" and len(argv) > 2:
        write(load(argv[2])[1])
    elif cmd == "auto" and len(argv) > 2:
        write(auto(argv[2]))
    elif cmd == "name" and len(argv) > 2:
        print("Automatic (wallpaper)" if argv[2] == "auto" else load(argv[2])[0])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
