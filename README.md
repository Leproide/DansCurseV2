<!--
  Dan's Curse V2 - README
  Author: https://github.com/Leproide
  License: GPL-3.0-or-later
-->

# Dan's Curse V2

Shader per [MediEvilRecomp ITA](https://github.com/Leproide/MediEvilRecomp-ITA), basato su [Dan's Curse](https://github.com/flafmg/DansCurse) di flaffymg e modificato con il permesso dell'autore. Rifà nebbia e illuminazione: luci, ombre, bagliori, raggi di luna, cielo e acqua con onde restano quelli dell'originale.

## Installazione

Dal gioco: **Mods → Explore Mod Hub → Dan's Curse V2**. Poi accendi la mod **Shaders** dal pannello **Mods** e seleziona **dans-curse-v2** dal menu **Shaders**. Richiede **Better rendering** attivo.

A mano: copia la cartella del repository in `shaders/dans-curse-v2/` accanto all'eseguibile.

## Cosa cambia rispetto all'originale

**Nebbia**
- Colore stabile: viene dal cielo visibile e cambia solo quando il cielo si vede bene. Nell'originale era la media dello schermo, quindi diventava il colore dei muri appena il cielo usciva dall'inquadratura.
- Luminosità regolabile (**Fog brightness**). Nell'originale era limitata a un valore fisso molto basso e in lontananza la nebbia diventava quasi nera.
- Foschia a terra appoggiata al pavimento: la quota del pavimento viene stimata dalle superfici visibili e la densità è integrata lungo il raggio di vista. Nell'originale era misurata rispetto all'altezza della telecamera e si spostava con lei.
- Banchi di foschia che si muovono lentamente (**Mist patches**, **Mist drift**) al posto di un gradiente uniforme.
- La luna schiarisce la nebbia quando la si guarda di fronte (**Fog moon glow**) e le sorgenti di luce hanno un alone (**Fog light halos**).
- Nebbia sul cielo calcolata dalla direzione di vista: l'orizzonte non si sposta più inclinando la telecamera.
- Il passaggio interno/esterno cambia inizio e densità della nebbia molto meno, senza "pompare" quando si guarda in alto o in basso.

**Illuminazione**
- La luce già presente nei colori del gioco viene modulata invece di essere moltiplicata da zero (**Relighting strength**): le zone in ombra restano leggibili invece di diventare fango.
- Ombre di contatto e occlusione ambientale filtrate nel tempo (**Temporal smoothing**), con riproiezione tramite la telecamera del frame precedente: niente più motivo a puntini.
- In lontananza resta la luce diffusa; spariscono solo ombre e occlusione. Nell'originale oltre una certa distanza tutto diventava un grigio piatto.
- Bagliore solo sulle vere sorgenti di luce (piccole e molto più luminose di ciò che hanno intorno). Nell'originale anche superfici arancioni grandi, come le zucche, diventavano luci.

I nomi dei parametri sono quelli dell'originale (`DC_*`), più i nuovi: `DC_RELIGHT`, `DC_TEMPORAL`, `DC_FOG_BRIGHT`, `DC_HAZE`, `DC_FOG_MOON`, `DC_FOG_LIGHTS`, `DC_MIST_NOISE`, `DC_MIST_SPEED`.

## Struttura

| Pass | File | Cosa fa |
|---|---|---|
| 0 | `geometry.slang` | normali e occlusione ambientale dalla profondità |
| 1 | `occlusion.slang` | ombre di contatto e accumulo temporale (nuovo) |
| 2-6 | `emissive.slang`, `glow_blur_*` | bagliore delle sorgenti di luce |
| 7 | `shafts.slang` | raggi di luna |
| 8 | `sky.slang` | cielo, interno/esterno, pavimento, colore della nebbia (4x1) |
| 9 | `composite.slang` | illuminazione, acqua, nebbia |
| 10-12 | `bloom_*` | bloom |
| 13 | `final.slang` | tonemap e colore |

## Licenza

Le modifiche della V2 sono rilasciate sotto **GPL-3.0-or-later** (vedi `LICENSE`). Il lavoro originale è di flaffymg; crediti di terze parti in `THIRD_PARTY.txt`.

## Autore

V2: https://github.com/Leproide
Originale: flaffymg (https://github.com/flafmg/DansCurse)
