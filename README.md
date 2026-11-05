<!--
  Dan's Curse V2 - README
  Author: https://github.com/Leproide
  License: GPL-3.0-or-later
-->

# Dan's Curse V2

Shader per [MediEvilRecomp ITA](https://github.com/Leproide/MediEvilRecomp-ITA), basato su [Dan's Curse](https://github.com/flafmg/DansCurse) di flaffymg e modificato per una migliore resa grafica. Rifà nebbia e illuminazione: luci, ombre, bagliori, raggi di luna, cielo e acqua con onde restano quelli dell'originale.

## Installazione

Dal gioco: **Mods → Explore Mod Hub → Dan's Curse V2**. Poi accendi la mod **Shaders** dal pannello **Mods** e seleziona **dans-curse-v2** dal menu **Shaders**. Richiede **Better rendering** attivo.

A mano: copia la cartella del repository in `shaders/dans-curse-v2/` accanto all'eseguibile.

**Consigliato:** in **Settings → Display** porta **Draw distance** a **3.00x**. Il gioco disegna il terreno solo fino a una distanza breve; la nebbia nasconde il limite di disegno, quindi con la distanza normale gli oggetti un po' lontani (recinzioni, lapidi) restano mezzi coperti. A 3x la nebbia copre solo il fondo della scena.

## Cosa cambia rispetto all'originale

**Nebbia**
- Nebbia di distanza lineare tra **Fog start** e **Fog end** (4500 e 14000 di default): parte più lontano e cresce in modo uniforme. **Fog** è l'opacità massima. Nell'originale era esponenziale e partiva a 2600.
- Colore stabile: viene dal cielo visibile e cambia solo quando il cielo si vede bene. Nell'originale era la media dello schermo, quindi diventava il colore dei muri appena il cielo usciva dall'inquadratura.
- Luminosità regolabile (**Fog brightness**). Nell'originale era limitata a un valore fisso molto basso e in lontananza la nebbia diventava quasi nera.
- Foschia a terra appoggiata al pavimento: la quota del pavimento viene stimata dalle superfici visibili e la densità è integrata lungo il raggio di vista. Nell'originale era misurata rispetto all'altezza della telecamera e si spostava con lei.
- Foschia a terra e foschia di base partono da **Mist start** (1800): intorno al personaggio l'aria resta pulita.
- Banchi di foschia che si muovono lentamente (**Mist patches**, **Mist drift**) al posto di un gradiente uniforme.
- La luna schiarisce la nebbia quando la si guarda di fronte (**Fog moon glow**) e le sorgenti di luce hanno un alone (**Fog light halos**).
- Nebbia sul cielo calcolata dalla direzione di vista: l'orizzonte non si sposta più inclinando la telecamera.
- Il passaggio interno/esterno cambia inizio e densità della nebbia molto meno, senza "pompare" quando si guarda in alto o in basso.
- **Disable fog**: spegne nebbia, foschia, nebbia sul cielo e aloni, e lascia tutto il resto (luci, ombre, riflessi, acqua, raggi di luna, sfumatura al nero del limite di disegno).
- **Keep game darkness in fog** (attivo di default): dove il gioco porta il terreno al nero (attorno ai buchi e ai bordi della mappa, con il colore dei vertici) nebbia, aloni, raggi di luna e riflessi delle luci non lo schiariscono più, e il vuoto sotto l'orizzonte resta nero anche visto di sbieco: gli scalini dei quadrati spariscono nel nero come nell'originale. Con MediEvilRecomp ITA il terreno vicino al vuoto viene sfumato al nero (opzione "Map edge fade").
- I buchi nel terreno restano neri come nell'originale: il vuoto visto ben sotto l'orizzonte non prende più nebbia e foschia (prima diventava una macchia grigia). La sfumatura del terreno verso il nero la fa il gioco attorno ai buchi e MediEvilRecomp ITA lungo i bordi della mappa (opzione Map edge fade), con il colore dei vertici.
- Limite di disegno nascosto (**Draw distance fade**): il gioco disegna il terreno a blocchi fino a una certa distanza e copre il taglio sfumando al nero. Con la nebbia chiara dell'originale i bordi dei blocchi e il vuoto dietro diventavano figure squadrate e tagli netti. Ora, come nell'originale, la geometria vicina al limite e il vuoto sotto l'orizzonte sfumano verso il nero (gli oggetti non galleggiano più su un fondo grigio), solo quando si vede del vuoto sotto l'orizzonte: davanti a un muro la nebbia non si avvicina più. Il limite arriva dal gioco (MediEvilRecomp ITA 1.1.6 o successivo); con versioni precedenti è stimato dalla geometria visibile. Il terreno arriva al nero già alla distanza di disegno del gioco: il gioco scarta solo i poligoni del terreno tutti oltre quella distanza, quindi il bordo a scalini (quadrati) sta tutto oltre e sparisce nel vuoto, anche se oggetti più lontani (case, recinzioni) spostano in là il limite stimato. **Draw distance debug** colora in rosso la geometria che sfuma e in verde quella oltre il limite.

**Luci delle fiamme e delle magie**
- Le sorgenti di luce (fiamme, scintille, magie: il runtime trasforma in luce ogni sprite luminoso del gioco) illuminano davvero: attenuazione marcata vicino alla sorgente, lato rivolto alla luce più chiaro dell'altro, riflesso speculare (**Light source shine**) e una parte che scalda oltre la luce del gioco e accende il bloom (**Light source heat**).
- Le luci color fuoco tremolano (**Fire flicker**), ognuna per conto suo.
- Ombre delle sorgenti di luce (**Light source shadows**): per ogni punto si guarda la luce che conta di più e si controlla se qualcosa si mette in mezzo. Vicino alla luce gli ostacoli sono ignorati, così torce e bracieri non oscurano la propria fiamma. Filtrate nel tempo come le altre ombre (nuovo pass `lightshadow.slang`).

**Illuminazione**
- La luce già presente nei colori del gioco viene modulata invece di essere moltiplicata da zero (**Relighting strength**): le zone in ombra restano leggibili invece di diventare fango.
- Ombre di contatto e occlusione ambientale filtrate nel tempo (**Temporal smoothing**), con riproiezione tramite la telecamera del frame precedente: niente più motivo a puntini.
- In lontananza resta la luce diffusa; spariscono solo ombre e occlusione. Nell'originale oltre una certa distanza tutto diventava un grigio piatto.
- Bagliore solo sulle vere sorgenti di luce (piccole e molto più luminose di ciò che hanno intorno). Nell'originale anche superfici arancioni grandi, come le zucche, diventavano luci.

I nomi dei parametri sono quelli dell'originale (`DC_*`), più i nuovi: `DC_RELIGHT`, `DC_TEMPORAL`, `DC_FOG_BRIGHT`, `DC_HAZE`, `DC_FOG_MOON`, `DC_FOG_LIGHTS`, `DC_MIST_NOISE`, `DC_MIST_SPEED`, `DC_FOG_EDGE`, `DC_FOG_END`, `DC_MIST_START`, `DC_LIGHT_SHINE`, `DC_LIGHT_HOT`, `DC_FLICKER`, `DC_LIGHT_SHADOWS`. `DC_FOG` ora va da 0 a 1 (opacità massima della nebbia di distanza).

## Struttura

| Pass | File | Cosa fa |
|---|---|---|
| 0 | `geometry.slang` | normali e occlusione ambientale dalla profondità |
| 1 | `occlusion.slang` | ombre di contatto e accumulo temporale (nuovo) |
| 2 | `lightshadow.slang` | ombre delle sorgenti di luce, accumulo temporale (nuovo) |
| 3-7 | `emissive.slang`, `glow_blur_*` | bagliore delle sorgenti di luce |
| 8 | `shafts.slang` | raggi di luna |
| 9 | `sky.slang` | cielo, interno/esterno, limite di disegno, pavimento, colore della nebbia (4x1) |
| 10 | `composite.slang` | illuminazione, luci puntiformi, acqua, nebbia |
| 11-13 | `bloom_*` | bloom |
| 14 | `final.slang` | tonemap e colore |

## Licenza

Le modifiche della V2 sono rilasciate sotto **GPL-3.0-or-later** (vedi `LICENSE`). Il lavoro originale è di flaffymg; crediti di terze parti in `THIRD_PARTY.txt`.

## Autore

V2: https://github.com/Leproide
Originale: flaffymg (https://github.com/flafmg/DansCurse)
