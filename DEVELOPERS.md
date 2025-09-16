# Ontwikkelaarsgids voor SeniorenSlim

Deze gids bevat technische instructies voor het opzetten, bouwen en testen van de SeniorenSlim-distributie.

## Structuur

```
seniorenslim/
├─ assets/
│  ├─ branding/            # logo, wallpaper, iconen (PNG/JPG)
│  └﹖ docs/                # quickstart.md, handleiding.md (CI rendert PDF)
├─ config/
│  ├─ desktop/
│  │  └﹖ skeleton/         # /etc/skel inhoud (autostart, Desktop .desktop files)
│  └﹖ apps/                # policies voor Chromium/Firefox
├─ scripts/
│  ├─ A_configurator_install.sh
│  ├─ A_update_buddy.sh
│  ├─ A_rustdesk_install.sh
│  ├─ B_build_iso.sh
│  └﹖ B_postinstall_hooks.sh
├─ iso/                    # build output (ISO-bestanden)
└﹖ .github/workflows/
   └﹖ build-iso.yml        # GitHub Actions workflow voor ISO-bouw
```

## Scripts

### A_configurator_install.sh

Dit script installeert alle benodigde pakketten, kopieert branding, maakt snelkoppelingen en stelt policies in.  
Gebruik het op een **verse** Zorin/Debian/Ubuntu-installatie:

```bash
curl -fsSL https://raw.githubusercontent.com/roppunt/seniorenslim/main/scripts/A_configurator_install.sh | sudo bash
```

### A_update_buddy.sh

Wordt automatisch geïnstalleerd door het configuratiescript. Het voert stille systeemupdates uit en toont na afloop een desktopmelding.

### A_rustdesk_install.sh

Installeert de RustDesk remote-support tool. Wordt standaard door het configuratiescript uitgevoerd.

### B_build_iso.sh

Een shellscript dat binnen een Docker-container een aangepaste Debian XFCE ISO bouwt met alle SeniorenSlim-branding. Vereist Docker en `live-build`.  
Voer uit vanuit de root van de repo:

```bash
bash scripts/B_build_iso.sh
```

Het script plaatst het ISO-bestand in `iso/` met een datumstempel.

### B_postinstall_hooks.sh

Bevat postinstall hooks die tijdens de ISO-bouw in de chroot worden uitgevoerd. Hier worden o.a. GRUB, Plymouth, LightDM, policies en firewall ingesteld.

## ISO-bouw via GitHub Actions

De workflow `.github/workflows/build-iso.yml` bouwt automatisch een ISO bij elke push naar de `main` branch. Het artefact wordt geüpload en is te vinden onder *Actions* → *Build SeniorenSlim ISO*.

## Branding-assets

- `logo.png`: wordt getoond in documentatie en (optioneel) opstartschermen.  
- `wallpaper.jpg`: bureaubladachtergrond voor nieuwe gebruikers.  
- `icons/*.png`: pictogrammen voor de snelkoppelingen.  

Vervang deze bestanden door definitieve ontwerpen wanneer beschikbaar.

## Policies

De bestanden in `config/apps/` bevatten JSON-policies voor Chromium en Firefox, waarmee de startpagina wordt ingesteld en ongewenste functies worden uitgeschakeld.

## Desktop-skeleton

De map `config/desktop/skeleton/` bootst `/etc/skel` na. Bestanden hieruit worden gekopieerd tijdens de ISO-bouw en door het configuratiescript voor nieuwe gebruikers.  
Belangrijkste elementen:

- `Desktop/*.desktop`: snelkoppelingen voor internet, e-mail, videobellen, foto's en bankieren.  
- `.config/autostart/seniorenslim-welcome.desktop`: start een PDF met een welkoms- en quickstartgids bij eerste login.

## Testen

1. Zet een virtuele machine of container op met een schone Debian- of Ubuntu-installatie (XFCE of MATE).  
2. Voer het configuratiescript uit via het curl-commando hierboven.  
3. Maak een nieuw gebruikersaccount en log in. Controleer:
   - Achtergrond en iconen verschijnen correct.
   - Chromium start op de juiste startpagina.
   - `update-buddy` staat in de cron (`crontab -l`).
   - RustDesk is geïnstalleerd (`systemctl status rustdesk`).
4. Voer systeemupdates uit (optioneel) en observeer de melding.

## Bekende beperkingen

- De huidige wallpaper is een tijdelijke placeholder (blauwe gradient) en kan worden vervangen.  
- Sommige banken kunnen aanvullende inlogmethodes vereisen; controleer altijd de URL voordat je bankeert.  
- Het buildscript verwacht dat Docker beschikbaar is; op sommige systemen kan extra configuratie nodig zijn.

## Extra tools

- **Shellcheck**: voer `shellcheck` uit op de scripts om syntax- en stijlfouten te detecteren.  
- **Markdownlint**: om de documentatie netjes te houden.

## Licentie en auteurs

Dit project is open source. Zie het bestand `LICENSE` voor de volledige licentietekst.  

Ontwikkeld door het SeniorenSlim-team, 2025.
