# hypr-setup

Arch Linux + **Hyprland** completo, do sistema recém-instalado ao desktop pronto:
um script (`install.sh`) e as configs (`dotfiles/`). Feito para ser usado **só com teclado**,
mas com tudo clicável para quem usa mouse.

- **Visual:** cores geradas a partir do wallpaper (imagem, GIF ou vídeo), aplicadas em todo o sistema.
  Ou um tema fixo: Catppuccin, Tokyo Night, Gruvbox, Nord, Rosé Pine, Everforest, Kanagawa, Dracula.
- **Ajustes ao vivo:** tamanho das fontes, espaço entre janelas e escala da tela por atalho,
  e uma central de controle com o resto (a barra fica só com o essencial).
- **Terminal:** kitty transparente + zsh com Starship, autosugestões, fzf, atuin (histórico), direnv e mise.
- **Editor:** Neovim (LazyVim) como IDE de Python / ciência de dados, com células estilo Jupyter.
- **Arquivos:** yazi. **Sistema:** em inglês, teclado ABNT2.
- **Idiomas do teclado:** português (ABNT2), inglês, russo e japonês (fcitx5 + Mozc).

---

## Instalação

**Pré-requisitos:** Arch Linux instalado (ex.: `archinstall`, perfil *minimal*), um usuário com
`sudo`, internet funcionando e `git` instalado.

```bash
sudo pacman -S --needed git
git clone <url-do-seu-repositório> ~/hypr-setup   # ou copie a pasta por pendrive
cd ~/hypr-setup
bash install.sh        # pede a senha do sudo uma vez
sudo reboot
```

Na tela de login, escolha a sessão **Hyprland**. No primeiro login o wallpaper animado é aplicado
e as cores são geradas. **SUPER + F1** mostra todos os atalhos.

Se você já tem configs na home, o script move as que forem diferentes para
`~/.config-backup/<data>/` antes de copiar as novas. Dá para rodá-lo de novo sem problema.

### Comandos do script

| Comando | O que faz |
|---|---|
| `./install.sh` | Instalação completa: pacotes, drivers, sistema, configs, shell e Neovim |
| `./install.sh dotfiles` | Só copia as configs de `dotfiles/` para a home (sem sudo) |
| `./install.sh nvim` | Só prepara o Neovim (plugins, parsers, servidores de linguagem) |
| `./install.sh save` | Copia as configs **atuais** da home para `dotfiles/` (use depois de personalizar) |
| `./install.sh sddm` | (Re)instala o tema da tela de login (pede sudo) |
| `./install.sh extras` | Firewall, zram, manutenção automática, tampa e limite de bateria (pede sudo) |

### O que ajustar antes de rodar

No topo do `install.sh`:

- **Idioma e teclado:** `SYS_LANG`, `CONSOLE_KEYMAP`, `XKB_LAYOUT` e `XKB_MODEL`.
  O teclado dentro do Hyprland fica em `dotfiles/.config/hypr/hyprland.lua` (`kb_layout`, `kb_model`).
- **Apps pessoais:** `PERSONAL_PKGS` e `PERSONAL_AUR` (Brave, KeePassXC, Claude Desktop, tmux…).
  O SUPER + B abre o Brave; se tirar o Brave, troque `browser` em `dotfiles/.config/hypr/binds.lua`.

### Hardware

O script detecta o hardware sozinho:

- **CPU:** instala o microcode certo (AMD ou Intel).
- **GPU:** AMD, Intel ou NVIDIA. Para NVIDIA usa o `nvidia-open`, que pede placa Turing
  (GTX 16xx / RTX 20xx) ou mais nova. Em kernels além do `linux` padrão, usa a versão `-dkms`.
- **Notebook híbrido** (integrada + NVIDIA): o desktop roda na GPU integrada para poupar bateria.
  Para usar a NVIDIA num app, abra com `prime-run <app>`. Também ativa a suspensão correta da NVIDIA e o
  RTD3: parada, a NVIDIA desliga sozinha (`cat /sys/bus/pci/devices/<id>/power/runtime_status` →
  `suspended`). Com monitor ligado na saída dela (HDMI deste notebook) ela fica ligada — é esperado.

Testado em: Ryzen 7 7735HS + Radeon 680M + RTX 4050 (notebook), Hyprland 0.56.

---

## O que vem instalado

| Função | Programa |
|---|---|
| Compositor | Hyprland 0.56 (config em **Lua**) |
| Barra | Waybar (+ central de controle em Rofi) |
| Lançador, emoji, calculadora, clipboard, menus | Rofi |
| Notificações | SwayNC |
| Idiomas do teclado | fcitx5 (+ Mozc para japonês) |
| Bloqueio de tela / inatividade | Quickshell (lock.qml, hyprlock de reserva) / hypridle |
| Luz noturna | hyprsunset |
| Wallpaper | awww (imagens e GIFs) e mpvpaper (vídeos) |
| Temas de cor (automático pelo wallpaper ou fixos) | theme.py (próprio) |
| Terminal | kitty |
| Shell | zsh + Starship, fzf, zoxide, lsd, bat |
| Editor | Neovim + LazyVim |
| Arquivos | yazi |
| Screenshots | grim + slurp + satty |
| Login | SDDM (tema próprio, igual à tela de bloqueio) |
| Áudio / rede / bluetooth | PipeWire / NetworkManager / Blueman |

---

## Atalhos

`SUPER` = tecla Windows. **SUPER + F1** abre esta lista pesquisável dentro do sistema.

### Apps e sistema
| Atalho | Ação |
|---|---|
| SUPER + Enter | Terminal |
| SUPER + Espaço (ou D) | Menu de apps |
| SUPER + SHIFT + Espaço | Executar comando |
| ALT + Tab | Lista de janelas |
| SUPER + E / B | Arquivos (yazi) / navegador |
| SUPER + V | Histórico da área de transferência |
| SUPER + ; / = | Emoji / calculadora |
| SUPER + N / SHIFT + N | Central de notificações / limpar |
| SUPER + SHIFT + C | Conta-gotas (copia a cor) |
| SUPER + A | Central de controle |
| SUPER + SHIFT + B | Mostrar/esconder a barra |
| SUPER + Esc | Bloquear tela |
| SUPER + X | Menu de energia |
| SUPER + CTRL + Q | Sair do Hyprland |

### Aparência (ao vivo, salva em `~/.config/hypr/look.conf`)
| Atalho | Ação |
|---|---|
| SUPER + ALT + `=` / `-` / `0` | Fontes maiores / menores / padrão |
| SUPER + CTRL + `=` / `-` / `0` | Espaço entre janelas maior / menor / padrão (pode segurar) |
| SUPER + CTRL + ALT + `=` / `-` / `0` | Escala da tela maior / menor / automática |

### Idioma do teclado
| Atalho | Ação |
|---|---|
| SUPER + CTRL + Espaço | Próximo idioma (+ SHIFT: anterior) |
| SUPER + CTRL + 1 / 2 / 3 / 4 | Português / inglês / russo / japonês |

### Proteção e manutenção

- **Atualizar o sistema:** comando `update` (ou central de controle → Tools → System update). Mostra as
  notícias do Arch desde a última atualização (às vezes pedem um passo manual), atualiza pacotes e AUR e
  depois avisa sobre arquivos `.pacnew`, firmware novo, pacotes órfãos e se é preciso reiniciar.
- **Backup:** restic, criptografado e incremental, no **Google Drive** (pasta `Backups/`), todo dia
  (ou assim que ligar, se perdeu o horário). Copia Documents, Projects, Desktop, Pictures, Music, chaves SSH,
  GPG e o chaveiro, sem `node_modules`, `.venv` e caches. Mantém 7 diários, 4 semanais e 6 mensais.
  - Primeira vez: `backup setup` (autoriza o Drive no navegador e cria a senha) e depois
    `backup drive-client`: cadastra a **sua** credencial do Google (passo a passo no próprio comando).
    A credencial compartilhada do rclone está sendo desativada e dá erro "Quota exceeded".
  - **Guarde a senha** (`~/.config/restic/password`) no KeePassXC: sem ela não há como recuperar nada.
  - `backup run` (agora), `backup status`, `backup list`, `backup restore latest ~/Restaurado`.
- **Firewall** (nftables): bloqueia conexões que chegam e libera as que saem. Regras em
  `system/etc/nftables.conf`, que também explica como abrir uma porta.
- **Automático:** TRIM do SSD (semanal), limpeza do cache do pacman (guarda as 3 últimas versões) e
  verificação de firmware (fwupd).
- **Antes de cada atualização** o pacman guarda a lista de pacotes (com versões) e uma cópia do `/etc` em
  `/var/backups/hypr-setup/` (as 10 últimas). Para voltar um pacote: `sudo pacman -U
  /var/cache/pacman/pkg/<pacote>-<versão>...`.
- **Kernel reserva** (`linux-lts`): se uma atualização do kernel quebrar o boot ou a NVIDIA, escolha
  *Advanced options → linux-lts* no GRUB. A NVIDIA e o limite de bateria usam DKMS e funcionam nos dois.
- **Mirrors:** o reflector escolhe toda semana os mais rápidos (Brasil + EUA, em
  `system/etc/xdg/reflector/reflector.conf`).
- **zram:** swap comprimida na memória (metade da RAM), usada antes da swap em disco. Deixa o sistema mais
  fluido quando a memória aperta.

## Notebook

- **Teclas de volume, mudo, microfone, brilho e Caps Lock** mostram um aviso rápido com o nível
  (`scripts/osd.sh`).
- **Tomada × bateria** (`scripts/power.sh`): ao tirar da tomada, a tela do notebook vai a 60 Hz e o perfil
  de energia a *power saver*; ao voltar, a tela volta a 165 Hz e o perfil que você usava. Para fixar uma
  taxa, defina `mode=` do monitor em Displays. Jogos e vídeos em tela cheia usam taxa adaptativa (VRR).
- **Vídeo pela GPU no Brave** (VA-API): YouTube e reuniões gastam menos bateria. Confira em
  `brave://gpu` ("Video Decode: Hardware accelerated") ou com `vainfo`.
- **Boot:** o menu do GRUB fica escondido (o boot não espera); segure **Esc** ou **Shift** ao ligar para
  ver o menu e escolher o `linux-lts`.
- **Bateria baixa:** aviso em 15%, alerta em 8% e suspensão automática em 4% (se continuar na bateria).
- **Tampa fechada com monitor externo:** desliga só a tela do notebook e você continua no monitor; ao abrir,
  ela volta com os seus workspaces. Sem monitor externo, fechar a tampa suspende (e bloqueia).
- **Limite de carga em 80%** (Acer, módulo `acer-wmi-battery`): prolonga a vida útil da bateria. Para
  carregar até 100% numa viagem: `echo 0 | sudo tee /sys/bus/wmi/drivers/acer-wmi-battery/health_mode`
  (volta a 80% no próximo boot, ou com `echo 1`).

## Git, SSH e terminal

- **Git** (`~/.config/git/config`): branch `main`, `pull` com rebase, `push` cria o upstream sozinho,
  diffs com **delta** (cores do tema), conflitos com o trecho original (zdiff3) e commits **assinados com a
  chave SSH**. Para o GitHub mostrar "Verified", suba a chave como chave de assinatura:
  `gh auth refresh -s admin:ssh_signing_key && gh ssh-key add ~/.ssh/id_ed25519.pub --type signing`.
  Ajustes só desta máquina (ex.: outro e-mail numa pasta do trabalho) vão em `~/.config/git/local`:
  ```ini
  [includeIf "gitdir:~/Projects/Trabalho/"]
      path = ~/.config/git/trabalho
  ```
- **Agente SSH** do gnome-keyring: carrega as chaves de `~/.ssh` e lembra a senha delas (o login destrava o
  chaveiro). Recomendado pôr senha na chave: `ssh-keygen -p -f ~/.ssh/id_ed25519`.
- **Ctrl+R** = atuin: histórico pesquisável com pasta, duração e se deu erro; dentro dele, Ctrl+R de novo
  filtra por sessão/pasta. Só local (sem conta). ↑ continua buscando pelo que já foi digitado.
- **direnv:** um `.envrc` na pasta do projeto carrega variáveis ao entrar e descarrega ao sair
  (`direnv allow` na primeira vez). **mise:** versões de Node/Python/Go… por projeto (`mise use node@22`).
- **Apps de terminal no tema:** btop (tema gerado pelo `theme.py`, com gradientes), lazygit e yazi (cores do
  terminal, seguem qualquer tema sozinhos). O terminal abre com o **fastfetch**; para desligar, ponha
  `export FASTFETCH_ON_START=0` no começo do `~/.zshrc`.
- `help <comando>` (tldr) mostra exemplos curtos; `locate <nome>` acha arquivos no disco todo na hora.
- **Pendrives/HDs externos** montam sozinhos em `/run/media/$USER/` (udiskie) com notificação.

## Gravação, texto da tela e reuniões

- **Gravar a tela:** SUPER + ALT + R (o monitor em foco, com o som do sistema) ou SUPER + ALT + SHIFT + R
  (uma área). Na central de controle → Tools também há "com microfone". Enquanto grava, aparece `󰑋 0:12`
  em vermelho na barra (clique para parar). Vídeos em `~/Videos/Recordings`.
- **Copiar texto da tela (OCR):** SUPER + CTRL + S, selecione a área e o texto vai para a área de
  transferência. Português e inglês; japonês e russo pela central de controle → Tools.
- **Compartilhar a tela em reuniões** (Meet, Teams, Zoom no navegador): o navegador abre uma janelinha para
  escolher a tela, a janela ou uma área. Teste antes de uma reunião importante em
  https://webrtc.github.io/samples/src/content/getusermedia/getdisplaymedia/

## Tela de login

A tela de login (SDDM) tem o mesmo visual da tela de bloqueio: wallpaper desfocado (animado, se o
wallpaper for vídeo ou GIF), relógio, saudação,
foto de perfil e campo de senha no cartão de vidro, com as cores do wallpaper. No rodapé: sessão (clique
para trocar), layout do teclado e botões de suspender, reiniciar e desligar.

- Fundo, cores e foto acompanham sozinhos as trocas de wallpaper, de modo de cor e de foto
  (`~/.config/hypr/scripts/sddm-sync.sh`, chamado pelo `wallpaper.sh`, pelo `avatar.sh` e no login).
  O SDDM não lê a sua home, então esses arquivos vão para `/usr/share/sddm/themes/hypr-setup/dynamic/`,
  pasta que pertence ao seu usuário.
- Aparece **espelhada em todos os monitores** conectados (o que você digita aparece em todos). Em
  notebook híbrido, os monitores ligados na NVIDIA são ativados por `system/sddm/Xsetup` ("reverse PRIME").
  O espelhamento vale só no login; a sessão usa o arranjo de Displays.
- **Fundo animado:** quando o wallpaper é vídeo ou GIF, o `sddm-sync.sh` gera uma versão já desfocada e
  escurecida (960×540, até 60 s) em `dynamic/background.mp4`. Leva alguns segundos, em segundo plano,
  a cada troca de wallpaper.
- O tema fica em `system/sddm/hypr-setup/` (QML). Depois de editar, rode `./install.sh sddm`.
  Para testar sem sair da sessão: `sddm-greeter-qt6 --test-mode --theme system/sddm/hypr-setup`.

## Wallpaper e cores
| Atalho | Ação |
|---|---|
| SUPER + SHIFT + W | Escolher wallpaper (com miniaturas) |
| SUPER + CTRL + W | Wallpaper aleatório |
| SUPER + SHIFT + T | Tema de cores: automático (do wallpaper) ou um dos temas fixos |

### Janelas
| Atalho | Ação |
|---|---|
| SUPER + Q | Fechar |
| SUPER + F / M | Tela cheia / maximizar |
| SUPER + T | Flutuante ↔ lado a lado |
| SUPER + C / P | Centralizar / fixar em todos os workspaces |
| SUPER + Y | Alternar divisão horizontal/vertical |
| SUPER + G, Tab, SHIFT + Tab | Agrupar em abas, próxima/anterior aba |
| SUPER + setas ou `h j k l` | Mover o foco |
| SUPER + SHIFT + setas/hjkl | Mover a janela |
| SUPER + CTRL + setas/hjkl | Redimensionar (ou SUPER + R, setas, Esc) |

### Workspaces
| Atalho | Ação |
|---|---|
| SUPER + 1…0 | Ir para o workspace (do monitor em foco) |
| SUPER + SHIFT + 1…0 | Mover a janela para o workspace (do monitor em foco) |
| SUPER + , / . | Workspace anterior / próximo (do monitor em foco) |
| SUPER + ' | Voltar ao último workspace |
| SUPER + W | Workspace vazio (do monitor em foco) |
| SUPER + O / SHIFT + O | Focar o próximo monitor / mandar a janela para ele |
| Teclas de brilho | Brilho do monitor em foco (notebook ou externo) |
| SUPER + S / ALT + S | Scratchpad: mostrar / mandar janela |

### Screenshots, gravação e texto da tela
| Atalho | Ação |
|---|---|
| SUPER + ALT + R | Gravar a tela (o monitor em foco); de novo para parar |
| SUPER + ALT + SHIFT + R | Gravar uma área |
| SUPER + CTRL + S | Copiar o texto de uma área da tela (OCR) |
| Print (ou SUPER + SHIFT + S) | Área, copiada e salva em `~/Pictures/Screenshots` |
| SHIFT + Print | Tela inteira |
| SUPER + Print | Área + editor (satty) |

### Mouse
- **Barra:** tudo é clicável.
  - Logo do Arch: apps (direito: atalhos). Relógio: calendário (direito: data completa).
  - Workspaces: os que têm janelas ficam com o número claro e um tracinho embaixo. Clique no título
    da janela (ao lado) lista as janelas de cada workspace (Enter vai para a janela).
  - Música (aparece quando algo toca): clique = play/pause, direito = próxima, roda = anterior/próxima.
  - `󰅁` à direita: passe o mouse para ver os apps em segundo plano (Wi-Fi, Bluetooth…).
  - `󰌌 PT` idioma do teclado: clique = próximo, direito = escolher, roda = trocar.
  - Wi-Fi: escolher rede. Volume: clique = mudo, direito = mixer, roda = volume.
  - Bateria: roda = brilho do monitor daquela barra.
  - `󰂚` notificações (direito: não perturbe). `󰒓` central de controle (direito: aparência). `󰐥` energia.
- **Janelas:** SUPER + arrastar com o botão esquerdo move, com o direito redimensiona.
  Também dá para arrastar as bordas.
- **Workspaces:** SUPER + roda troca; no touchpad, 3 dedos na horizontal.

---

## Vários monitores

- **Cada monitor tem seus próprios workspaces 1–10.** SUPER + 1…0 e a barra de cada monitor valem só para ele.
  Por dentro, a tela do notebook usa os workspaces 1–10 e os outros monitores 11–20, 21–30 (em ordem de
  conector, não de posição: reposicionar as telas não embaralha os workspaces). A barra mostra 1–10 em
  todos. Os workspaces 1–5 de cada monitor aparecem sempre, mesmo vazios.
- **Conectar ou desconectar** um monitor reorganiza os workspaces e reinicia o wallpaper animado sozinho.
- SUPER + O foca o próximo monitor e SUPER + SHIFT + O manda a janela para ele.
- **Configurar as telas:** central de controle → **Displays**. Para cada monitor: posição (à esquerda,
  direita, acima ou abaixo de outro), resolução e taxa, escala, rotação, espelhar outro monitor,
  desligar/ligar, voltar ao automático. Vale na hora e fica salvo em `~/.config/hypr/monitors.conf`,
  pela descrição do monitor (continua valendo se trocar de porta). Sem ajuste, tudo é automático
  (o novo monitor fica à direita) e a escala segue SUPER + CTRL + ALT + `=` / `-`.
- **Brilho independente:** as teclas de brilho mudam o monitor em foco; a roda do mouse na bateria
  muda o monitor daquela barra; central de controle → Brightness lista todos.
  Monitores externos usam **DDC/CI**: ligue a opção "DDC/CI" no menu do próprio monitor. Teste com
  `ddcutil detect`. Monitores que não suportam continuam com o brilho pelos botões deles.
- Código: `~/.config/hypr/workspaces.lua`, `monitors.lua`, `scripts/displays.sh` e `scripts/brightness.sh`.

## Barra e central de controle

A barra mostra só o essencial, em "ilhas": workspaces e janela ativa à esquerda; relógio e música no
centro; monitoramento, Wi-Fi, volume, bateria, notificações, central de controle e energia à direita.

A ilha de **monitoramento** mostra o uso de CPU, o uso da GPU mais ocupada, a temperatura da CPU, a RAM e
o disco `/`. Cada item fica amarelo ou vermelho com carga ou calor. O tooltip traz os detalhes de cada
placa (uso, temperatura, VRAM, consumo) e de todos os sensores, e o clique abre o **btop**. A NVIDIA
só é consultada se já estiver acordada, para a leitura não tirar a placa do modo de economia. Script:
`~/.config/hypr/scripts/sysmon.sh` (`gpu`, `temp`, `top`).

O botão `󰒓` (ou **SUPER + A**) abre a **central de controle**, um painel abaixo da barra com:

- **Appearance:** fontes, espaço entre janelas, escala da tela, wallpaper, modo de cor, foto de perfil,
  mostrar/esconder a barra.
- **Do not disturb**, **Keep screen awake** (pausa o bloqueio automático) e **Night light** (tela mais quente).
- **Brightness** (por monitor) e **Displays** (posição, resolução, escala, rotação, espelhar, ligar/desligar).
- **Power profile**, **Wi-Fi**, **Bluetooth** (liga/desliga e parear), **Audio mixer**
  e **Keyboard** (idioma e configurações do fcitx5).
- **Tools:** screenshots, conta-gotas, clipboard, emoji, calculadora, monitor do sistema e atalhos.

Navegue com as setas ou digite para filtrar. Os ajustes (fonte maior, brilho, liga/desliga…) deixam
o painel aberto: aperte Enter de novo para repetir. Quando algo foge do normal (tela sempre acesa,
luz noturna, perfil de energia diferente do *balanced*, Bluetooth conectado), o ícone aparece ao
lado do `󰒓` na barra.

Script: `~/.config/hypr/scripts/controlcenter.sh` (`status`, ou o nome de um submenu para abri-lo direto).

## Fontes, espaço entre janelas e escala

- **Fontes** (SUPER + ALT + `=` / `-`): em passos de 10%, de 50% a 200%. Muda barra, menus, notificações,
  terminais (inclusive os abertos) e apps GTK e Qt (os já abertos atualizam ao reabrir).
- **Espaço entre janelas** (SUPER + CTRL + `=` / `-`): o espaço até a borda da tela acompanha.
- **Escala da tela** (SUPER + CTRL + ALT + `=` / `-`): aumenta ou diminui **tudo** (fontes, ícones,
  janelas). Neste notebook (1920×1080) a escala automática é 1.5. Se tudo parece grande, experimente
  1.25 ou 1.2. `0` volta à automática.
- Os valores ficam em `~/.config/hypr/look.conf` e continuam depois de reiniciar (o `hyprland.lua`
  lê esse arquivo). Script: `~/.config/hypr/scripts/look.sh font|gaps|scale up|down|reset`.
- Os tamanhos ficam em arquivos gerados pelo script (não edite à mão): `waybar/font.css`,
  `swaync/font.css`, `rofi/font.rasi` e `kitty/font.conf`. Os tamanhos-base (em 100%) estão no `look.sh`.

## Idiomas do teclado

Quatro idiomas, gerenciados pelo **fcitx5**: português (ABNT2), inglês (`us`), russo (`ru`) e japonês (Mozc).
O idioma vale para todos os apps ao mesmo tempo, e a barra mostra o atual (`PT` / `EN` / `RU` / `JA`).

- **Trocar:** SUPER + CTRL + Espaço, SUPER + CTRL + 1…4, clique na barra ou central de controle → Keyboard.
- **Atalhos do sistema** continuam no layout ABNT2, qualquer que seja o idioma (SUPER + Q fecha mesmo em russo).
  Ctrl+Espaço fica livre (o Neovim usa).
- **Japonês:** digite em romaji (`nihongo`) que vira hiragana. **Espaço** converte para kanji
  (Espaço de novo ou setas escolhem), **Enter** confirma. F7 = katakana, F10 = romaji. Esc cancela.
- **Senha e tela de bloqueio:** sempre no ABNT2 (o fcitx5 não age em campos de senha).
- **Mudar a lista ou a ordem:** central de controle → Keyboard → *Input method settings* (`fcitx5-configtool`),
  ou edite `~/.config/fcitx5/profile`. O inglês usa o layout `us`: no teclado ABNT2 alguns símbolos mudam
  de lugar (ex.: `;` fica na tecla do `ç`). Se preferir, troque por `keyboard-us-intl` ou outro.
- **Apps:** GTK, Qt, kitty e apps X11 funcionam direto. Brave e Claude Desktop precisam das flags em
  `~/.config/brave-flags.conf` e `~/.config/claude-desktop-flags.conf` (já incluídas). Para outro app
  Electron/Chromium, abra com `--enable-wayland-ime --wayland-text-input-version=3`.
- A janela de candidatos do japonês segue as cores do wallpaper e o tamanho de fonte do `look.sh`.
- **Problemas:** `fcitx5-diagnose` mostra o que falta. Script: `~/.config/hypr/scripts/keyboard.sh`.

## Tela de bloqueio

**SUPER + Esc**, ou sozinha depois de 5 min parado. Mostra o wallpaper atual desfocado, relógio, saudação,
o campo de senha num cartão de vidro e, no rodapé, a música tocando, o layout do teclado e a bateria.

- **Foto de perfil** no lugar do ícone: central de controle → Appearance → **Photo**. Mostra as imagens
  mais recentes de Pictures, Downloads e Desktop (ou *Browse…* para escolher qualquer arquivo pelo yazi).
  A foto é recortada em quadrado (as em pé, mais perto do topo, onde costuma estar o rosto) e salva em
  `~/.face`. Na mesma tela dá para remover. Script: `~/.config/hypr/scripts/avatar.sh pick|browse|set|remove`.
- O fundo é um quadro do wallpaper, salvo em `~/.cache/wallpaper/lock.png` a cada troca.
- Esc ou Ctrl+U limpam a senha. Com Caps Lock ligado, a borda do campo fica amarela.

## Wallpaper e cores

- Coloque arquivos em `~/Pictures/Wallpapers`: png, jpg, webp, gif, mp4, webm, mkv ou mov.
  O padrão é `aurora.mp4` (animado, loop de 20 s).
- Vídeos pausam sozinhos no monitor em que ficam cobertos (ex.: janela em tela cheia), para poupar
  bateria. Cada monitor tem o seu processo (mpvpaper), e o outro continua animado.
- **Temas** (SUPER + SHIFT + T, ou central de controle → Appearance → Theme):
  - **Automatic:** as cores saem de cada wallpaper (num vídeo ou GIF, de um quadro). A cor dominante
    tinge o fundo, e o acento principal (bordas, workspace ativo, menus) é a cor mais viva que
    contrasta com ela: o rosa da árvore no céu azul, o vermelho do portal na noite… Os acentos
    ficam vivos e legíveis no fundo escuro. Wallpaper sem cor gera acentos discretos. Vermelho, verde, amarelo e laranja
    ficam fixos, para manter o significado (erros, bateria…).
  - **Temas fixos:** Catppuccin Mocha, Tokyo Night, Gruvbox, Nord, Rosé Pine, Everforest, Kanagawa e
    Dracula. O menu mostra amostras de cor e fica aberto para você ir provando.
  - O tema muda na hora: bordas das janelas, workspace ativo, barra, menus, notificações, terminal,
    Neovim, tela de bloqueio, tela de login, apps GTK e janela do japonês.
  - No seletor de wallpaper, **Alt+T** alterna entre Automatic e o último tema fixo.
- **Criar um tema:** copie um arquivo de `~/.config/hypr/themes/palettes/`, troque o nome (`# name:`)
  e as cores. Ele aparece no menu sozinho. `mauve` é o acento principal (bordas, workspace ativo,
  seleção) e `blue` o segundo tom dos gradientes.
- **Script:** `~/.config/hypr/scripts/wallpaper.sh` com `set <arquivo>`, `pick`, `random`, `restore`
  e `theme auto|<tema>|toggle`. Gerador das cores: `~/.config/hypr/themes/theme.py` (`list`, `set`, `auto`).

## Terminal (zsh)

- **Prompt:** pasta, branch e status do git, versão do Python, `.venv` ativa e tempo de comandos longos.
- **Histórico:** ↑/↓ buscam pelo que já foi digitado. **Ctrl+R** pesquisa o histórico.
- **fzf:** **Ctrl+T** busca arquivos (com prévia) e **Alt+C** pula para uma pasta.
- **Navegação:** `z <nome>` vai a pastas já usadas e `y` abre o yazi (ao sair, o terminal fica na pasta).
- **Listagem:** `ls` / `ll` / `la` / `lt` usam o lsd (ícones, grade compacta, status do git).
- **Python:** a `.venv` do projeto ativa sozinha ao entrar na pasta.
  `mkds <nome>` cria um projeto de dados com uv: pandas, numpy, polars, scikit-learn,
  matplotlib, seaborn, ipython, ruff e pytest.
- **Transparência:** `Ctrl+Shift+A` e depois `M` / `L` deixa o fundo do kitty mais ou menos opaco.

## Neovim (IDE para Python / data mining)

`<espaço>` mostra todos os atalhos.

- **Python:** basedpyright (tipos), ruff (lint e formatação ao salvar), debugger (debugpy),
  testes (pytest) e seletor de venv (`<espaço> c v`).
- **Células estilo Jupyter:** separe o código com `# %%`.
  - **Shift+Enter** roda a célula no IPython da `.venv` e vai para a próxima.
  - `]j` / `[j` navegam entre células e `<espaço> j a` cria uma célula nova.
  - `<espaço> j` reúne o resto: abrir/fechar o REPL, rodar linha, seleção ou arquivo, interromper…
- **Notebooks `.ipynb`:** abrem como código com células `# %%` e salvam de volta mantendo as saídas.
- **Dados:** CSV/TSV abrem como tabela (`Tab` pula colunas) e SQL tem navegador de bancos (`<espaço> D`).
- **Gráficos:** os do matplotlib abrem em janela flutuante.
- **Visual:** fundo transparente, com as cores do wallpaper atualizadas ao vivo.

## Arquivos (yazi)

SUPER + E, ou `y` no terminal.

- **Navegar:** setas ou `h j k l`. `Enter` abre e `.` mostra os ocultos.
- **Copiar e mover:** `Espaço` seleciona, `y` / `x` / `p` copia / recorta / cola.
- **Arquivos:** `d` manda para a lixeira, `a` cria (termine com `/` para pasta) e `r` renomeia.
- **Busca:** `/` busca e `z` usa o zoxide.
- **Ajuda:** `F1` mostra todos os atalhos.

---

## Estrutura

```
hypr-setup/
├── install.sh                    # instalação / deploy / save
├── README.md
├── system/sddm/                  # tela de login: tema hypr-setup/ (QML) e Xsetup (todos os monitores)
├── system/etc/                   # firewall, zram, tampa, limite de bateria (instalados no /etc)
└── dotfiles/                     # espelho da home
    ├── .zshrc
    ├── .config/
    │   ├── hypr/                 # hyprland.lua, binds.lua, rules.lua, colors.lua (gerado),
    │   │   │                     #   workspaces.lua, monitors.lua + monitors.conf (telas), look.conf,
    │   │   ├── themes/           # theme.py (cores) + palettes/ (temas fixos)
    │   │   │                     #   hyprlock, hypridle
    │   │   └── scripts/          # wallpaper, look, controlcenter, displays, brightness, keyboard,
    │   │                         #   avatar, sddm-sync, powermenu, lockinfo, screenshot, clipboard, keybinds,
    │   │                         #   update, backup, record, ocr, lid, battery-watch, bar, media
    │   ├── fcitx5/               # idiomas do teclado (profile), atalhos e aparência
    │   ├── brave-flags.conf  claude-desktop-flags.conf   # IME no Wayland
    │   ├── waybar/  rofi/  swaync/  kitty/  yazi/  lsd/  starship.toml
    │   ├── nvim/                 # LazyVim + plugins/datascience.lua, colorscheme.lua
    │   └── gtk-3.0/  gtk-4.0/  user-dirs.*
    ├── .icons/default/           # cursor
    ├── .local/share/applications/yazi-kitty.desktop
    ├── .local/share/fcitx5/themes/hypr-setup/   # tema do fcitx5 (gerado pelo theme.py)
    └── Pictures/Wallpapers/      # aurora.mp4, catppuccin-mountains.png
```

## Mantendo atualizado (GitHub)

Esta pasta é **autossuficiente**: com ela, uma máquina com Arch recém-instalado fica igual a esta,
sem copiar mais nada. Depois de mudar algo no sistema:

```bash
cd ~/hypr-setup
./install.sh save                 # traz as configs atuais da home para dotfiles/
git add -A && git commit -m "ajustes" && git push
```

**O que vai junto:** pacotes (inclusive drivers, detectados na hora), configurações do sistema
(idioma, teclado, login, GPU, serviços), todas as configs da lista `MANAGED` do `install.sh`,
apps padrão (`mimeapps.list`), preferências de fonte/gaps/escala e o modo de cor
(`~/.config/hypr/look.conf`) e os dois wallpapers padrão.

**O que não vai (arquivos pessoais):** seus wallpapers, a foto de perfil (`~/.face`), chaves SSH,
banco do KeePassXC, perfis dos navegadores (use a sincronização do navegador), login do Claude,
dicionário do Mozc e `~/.claude` (configuração do Claude Code, que é do trabalho). Numa máquina nova,
se copiar seus wallpapers para `~/Pictures/Wallpapers` antes do primeiro login, o último usado (lembrado
no `look.conf`) já entra; senão entra o padrão.

Se passar a configurar um app novo, acrescente o caminho dele ao array `MANAGED` no `install.sh`.

## Testar numa VM

`test/vm.sh` instala tudo do zero numa máquina virtual (QEMU/KVM, UEFI, vídeo 3D), sem tocar no
seu sistema. Os arquivos ficam em `~/VMs/hypr-setup-test`; a VM tem 4 vCPUs, 6 GB e SSH em `localhost:2222`.

```bash
test/vm.sh deps            # mostra o comando do QEMU com vídeo 3D (rode com sudo)
test/vm.sh iso             # baixa a ISO do Arch e confere o sha256
test/vm.sh create          # disco de 40 GB + NVRAM do UEFI
test/vm.sh live            # liga pela ISO; a chave SSH entra sozinha (cloud-init)
test/vm.sh install         # Arch base: GRUB UEFI, ext4, usuário tester/tester (test/arch-base.sh)
test/vm.sh ssh poweroff && test/vm.sh run    # religa pelo disco
test/vm.sh setup           # copia este repositório e roda ./install.sh (log: test/vm.sh ssh tail -f install.log)
test/vm.sh destroy         # apaga a VM (a ISO fica)
```

Ao final, faça login na janela da VM (tester / tester). O sudo da VM não pede senha e a porta 22 fica
liberada no firewall (`/etc/nftables.d/input/ssh.nft`) — só na VM de teste.

## Dicas e problemas conhecidos

- **Config do Hyprland:** desde a 0.55 é em **Lua** (`hyprland.lua`), não mais `hyprland.conf`.
  Erros aparecem na tela e em `hyprctl configerrors`.
- **Barra sumiu?** A Waybar é iniciada por `~/.config/hypr/scripts/bar.sh`, que a reinicia sozinha se
  ela travar (aparece uma notificação). Se você fechou de propósito, abra de novo com `bar.sh`.
  A música na barra vem de `scripts/media.sh` (playerctl), e não do módulo `mpris`, que travava a barra.
- **Comandos novos na Waybar:** use `setsid -f <comando>` em `on-click`. A sessão roda presa ao
  `tty1`, e sem o `setsid` programas como o Rofi podem ficar congelados.
- **Tamanho de fonte na barra/menus:** não ponha `font-size` em `waybar/style.css`, `swaync/style.css`
  ou `rofi/theme.rasi`. Os tamanhos vêm dos arquivos gerados pelo `look.sh`.
- **Fechar o Rofi por script:** use `pkill -x rofi`. Sem o `-x`, ele casa com o
  `power-profiles-daemon`.
- **NVIDIA:** `nvidia-smi` mostra se a placa está em uso. Ela desliga sozinha quando ociosa.
- **Neovim:** se faltar algo, rode `./install.sh nvim` ou use `:Lazy`, `:Mason` e `:checkhealth`.
