# Development Plan for a Mobile GIS Application for Butterfly Monitoring

> **Note:** This document is an English version of the original specification. It is intended as a software design document for developers and collaborators. The application follows an **offline-first** architecture and is built around standardized butterfly monitoring using OGC standards.


# Development Plan for a Mobile GIS Application for Butterfly Monitoring

## 1. Project Overview

Cilj projekta je razvoj interoperabilne mobilne GIS aplikacije namenjene biolozima koji sprovode terenska istraživanja dnevnih leptira. Aplikacija treba da omogući:

- standardizovano sprovođenje transektnih istraživanja;
- evidentiranje pojedinačnih nalaza leptira;
- beleženje brojnosti, ponašanja, pola, razvojnog stadijuma i pouzdanosti determinacije;
- kartiranje biljaka hraniteljki, nektarskih biljaka i staništa;
- povezivanje bioloških nalaza sa vremenskim i mikroklimatskim podacima;
- rad bez internet konekcije;
- kasniju sinhronizaciju sa centralnim serverom;
- pregled i osnovnu analizu podataka na karti;
- izvoz podataka za dalju statističku analizu u R-u, Python-u, QGIS-u ili drugom softveru.

Projekat treba da bude predstavljen kao razvoj i evaluacija interoperabilnog sistema zasnovanog na OGC standardima, a ne kao pokušaj implementacije svakog standarda od početka.

---

## 2. Predloženi naziv rada

**Razvoj interoperabilne mobilne GIS aplikacije za standardizovano praćenje dnevnih leptira, njihovih staništa i uslova sredine primenom OGC standarda**

Alternativni naziv:

**Primena OGC standarda u razvoju mobilnog GIS sistema za terenski monitoring dnevnih leptira**

---

## 3. Main Objective

Razviti i testirati mobilni GIS sistem za standardizovano prikupljanje, čuvanje, razmenu, prikaz i analizu podataka o:

- rasprostranjenosti leptira;
- brojnosti leptira;
- fenologiji;
- ponašanju;
- stanišnim karakteristikama;
- biljkama hraniteljkama;
- nektarskim resursima;
- vremenskim i mikroklimatskim uslovima;
- uloženom terenskom naporu.

---

## 4. Biological Research Questions

Sistem treba da omogući prikupljanje podataka kojima se mogu testirati sledeća pitanja:

1. Kako se bogatstvo vrsta i brojnost leptira razlikuju između tipova staništa?
2. Kako temperatura, vetar, oblačnost i osunčanost utiču na aktivnost i detektabilnost leptira?
3. Da li je prisustvo specijalističkih vrsta povezano sa prisustvom ili obilnošću biljaka hraniteljki?
4. Da li se reproduktivna ponašanja, poput polaganja jaja, češće registruju unutar određenih stanišnih mikrocelina?
5. Kako se sastav zajednice leptira menja tokom sezone?
6. Koji lokaliteti predstavljaju hranilišta, reproduktivna staništa ili koridore kretanja?
7. Koliko se podaci prikupljeni mobilnom aplikacijom mogu pouzdano standardizovati, sinhronizovati i razmenjivati preko OGC servisa?

Za master rad nije neophodno statistički odgovoriti na sva pitanja. Dovoljno je odabrati dva ili tri pitanja za demonstraciju sistema.

---

## 5. Proposed Master's Thesis Scope

### 5.1. Mandatory Component — MVP

MVP treba da sadrži:

1. upravljanje korisnicima i projektima;
2. kreiranje i preuzimanje transekata;
3. pokretanje terenske posete;
4. automatsko beleženje rute posmatrača;
5. unos opažanja leptira;
6. unos terenskog napora i vremenskih uslova;
7. kartiranje biljaka hraniteljki i stanišnih elemenata;
8. offline čuvanje podataka;
9. sinhronizaciju sa serverom;
10. pregled nalaza i transekata na mapi;
11. osnovni izvoz podataka;
12. OGC API – Features interfejs za prostorne objekte.

### 5.2. Recommended Extensions

- povezivanje sa mikroklimatskim senzorima preko SensorThings API-ja;
- automatsko preuzimanje vremenskih podataka;
- pregled fenologije i osnovnih indikatora monitoringa;
- validacija determinacija;
- kontrola kvaliteta podataka.

### 5.3. Experimental Component

- kratkotrajno praćenje kretanja pojedinačnog leptira;
- predstavljanje putanje preko OGC API – Moving Features;
- povezivanje događaja na putanji sa ponašanjem;
- EDR pristup prostorno-vremenskim vremenskim podacima.

Moving Features i EDR ne treba da budu uslov da osnovna aplikacija radi.

---

## 6. User Roles

### 6.1. Terenski istraživač

Može da:

- preuzme projekat i transekte;
- započne i završi terensku posetu;
- beleži nalaze;
- dodaje fotografije;
- kartira biljke i staništa;
- radi offline;
- sinhronizuje podatke;
- pregleda svoje podatke.

### 6.2. Ekspert-validator

Može da:

- pregleda nalaze kojima je potrebna potvrda;
- pregleda fotografije;
- potvrdi ili izmeni determinaciju;
- upiše komentar;
- označi nalaz kao potvrđen, nepotvrđen ili neodrediv.

### 6.3. Koordinator projekta

Može da:

- kreira projekat;
- definiše transekte i sektore;
- dodeljuje istraživače;
- uređuje šifarnike;
- pregleda sve podatke;
- zaključava završene posete;
- izvozi podatke;
- prati sinhronizaciju i greške.

### 6.4. Administrator

Upravlja:

- korisnicima;
- ulogama;
- serverima;
- konfiguracijom;
- rezervnim kopijama;
- audit zapisima.

Za MVP se uloge mogu pojednostaviti na `researcher` i `admin`.

---

## 7. Proposed Field Protocol

## 7.1. Metod

Osnovni metod je ponovljeno transektno posmatranje dnevnih leptira, zasnovano na Pollard walk pristupu.

Pre početka projekta biolog treba da definiše:

- trasu svakog transekta;
- dužinu transekta;
- sektore transekta;
- dozvoljeni period sezone;
- preporučeno doba dana;
- minimalne vremenske uslove;
- ciljnu učestalost obilazaka.

Aplikacija ne treba da „zakuca“ jednu univerzalnu vrednost, već da omogući podešavanje protokola po projektu.

## 7.2. Podaci o poseti

Svaka poseta mora imati:

- jedinstveni ID;
- projekat;
- transekt;
- posmatrača;
- datum;
- vreme početka;
- vreme završetka;
- trajanje;
- pređenu udaljenost;
- broj posmatrača;
- metod;
- temperaturu;
- vetar;
- oblačnost;
- padavine;
- procenu prikladnosti uslova;
- belešku;
- status posete.

Predloženi statusi:

- `draft`;
- `in_progress`;
- `completed`;
- `synced`;
- `reviewed`;
- `locked`;
- `cancelled`.

## 7.3. Nulti nalaz

Aplikacija mora razlikovati:

- završenu posetu bez zabeleženih leptira — pravi nulti nalaz;
- posetu koja nije sprovedena;
- prekinutu ili nevažeću posetu;
- nedostajući podatak.

Završavanje posete bez opažanja mora zahtevati eksplicitnu potvrdu:

> „Tokom kompletne standardizovane posete nije primećen nijedan leptir.“

## 7.4. Beleženje rute

Tokom aktivne posete aplikacija periodično beleži poziciju posmatrača:

- podrazumevani interval: 5–10 sekundi;
- prilagodljiv interval zbog baterije;
- vreme;
- koordinata;
- horizontalna preciznost;
- brzina;
- pravac;
- izvor lokacije.

Ruta služi za:

- proveru da je transekt zaista obiđen;
- računanje pređene udaljenosti;
- prikaz prostorne pokrivenosti;
- povezivanje opažanja sa sektorom transekta.

---

## 8. Data Model

## 8.1. Project

Polja:

- `id`;
- `name`;
- `description`;
- `owner_id`;
- `start_date`;
- `end_date`;
- `default_crs`;
- `protocol_version`;
- `taxon_list_version`;
- `created_at`;
- `updated_at`.

## 8.2. User

Polja:

- `id`;
- `name`;
- `email`;
- `role`;
- `organization`;
- `active`;
- `created_at`;
- `updated_at`.

## 8.3. Transect

Geometrija: `LineString`.

Polja:

- `id`;
- `project_id`;
- `code`;
- `name`;
- `description`;
- `target_length_m`;
- `habitat_summary`;
- `active`;
- `geometry`;
- `created_at`;
- `updated_at`.

## 8.4. TransectSection

Geometrija: `LineString` ili segment originalne trase.

Polja:

- `id`;
- `transect_id`;
- `section_code`;
- `sequence_number`;
- `habitat_type_id`;
- `management_type`;
- `notes`;
- `geometry`.

Sekcije omogućavaju analizu nalaza po mikro-staništu.

## 8.5. SurveyVisit

Polja:

- `id`;
- `project_id`;
- `transect_id`;
- `observer_id`;
- `protocol_version`;
- `started_at`;
- `ended_at`;
- `duration_seconds`;
- `distance_walked_m`;
- `observer_count`;
- `survey_method`;
- `temperature_start_c`;
- `temperature_end_c`;
- `wind_beaufort_start`;
- `wind_beaufort_end`;
- `cloud_cover_start_pct`;
- `cloud_cover_end_pct`;
- `precipitation`;
- `weather_suitable`;
- `zero_observation_confirmed`;
- `notes`;
- `status`;
- `device_id`;
- `created_offline`;
- `created_at`;
- `updated_at`;
- `server_version`.

## 8.6. SurveyTrackPoint

Geometrija: `Point`.

Polja:

- `id`;
- `survey_visit_id`;
- `recorded_at`;
- `geometry`;
- `accuracy_m`;
- `altitude_m`;
- `speed_m_s`;
- `heading_deg`;
- `provider`;
- `sequence_number`.

Na serveru se pojedinačne tačke mogu agregirati u `LineString` radi prikaza.

## 8.7. Taxon

Polja:

- `id`;
- `scientific_name`;
- `author`;
- `rank`;
- `genus`;
- `family`;
- `vernacular_name_sr`;
- `vernacular_name_en`;
- `accepted_name_id`;
- `taxon_source`;
- `taxon_source_id`;
- `active`;
- `identification_notes`.

Poželjno je imati verzionisan taksonomski šifarnik.

## 8.8. ButterflyObservation

Geometrija: `Point`.

Obavezna polja:

- `id`;
- `survey_visit_id`;
- `observed_at`;
- `taxon_id`;
- `count`;
- `geometry`;
- `identification_confidence`;
- `recorded_by`;
- `created_at`;
- `updated_at`.

Opciona polja:

- `transect_section_id`;
- `sex`;
- `life_stage`;
- `behaviour`;
- `microhabitat`;
- `flight_direction_deg`;
- `photo_count`;
- `notes`;
- `location_accuracy_m`;
- `validation_status`;
- `validated_taxon_id`;
- `validated_by`;
- `validated_at`;
- `validation_comment`;
- `host_plant_record_id`;
- `nectar_plant_record_id`;
- `source`;

Predložene vrednosti za `source`:

- `transect`;
- `incidental`;
- `focal_follow`;
- `larval_search`;
- `host_plant_search`.

## 8.9. IdentificationConfidence

Predložene vrednosti:

- `confirmed_in_field`;
- `probable`;
- `photo_required`;
- `genus_only`;
- `species_group`;
- `unknown`;
- `expert_review_required`.

## 8.10. Sex

- `male`;
- `female`;
- `mixed`;
- `unknown`;
- `not_applicable`.

Kod grupnog nalaza može biti `mixed`.

## 8.11. LifeStage

- `egg`;
- `larva`;
- `pupa`;
- `adult`;
- `unknown`.

## 8.12. Behaviour

Moguće je dozvoliti više vrednosti:

- `flying`;
- `resting`;
- `basking`;
- `nectaring`;
- `courtship`;
- `mating`;
- `territorial`;
- `oviposition`;
- `mud_puddling`;
- `feeding_on_fruit`;
- `feeding_on_sap`;
- `larval_feeding`;
- `other`;
- `unknown`.

## 8.13. Photo

Polja:

- `id`;
- `observation_id`;
- `local_path`;
- `server_uri`;
- `mime_type`;
- `file_size`;
- `sha256`;
- `captured_at`;
- `uploaded_at`;
- `is_primary`;
- `metadata_json`.

Fotografije ne treba čuvati kao velike binarne objekte direktno u glavnim tabelama baze. Bolje je koristiti objektno skladište, a u bazi čuvati URI i metapodatke.

## 8.14. PlantTaxon

Polja:

- `id`;
- `scientific_name`;
- `family`;
- `vernacular_name`;
- `taxon_source`;
- `taxon_source_id`;
- `active`.

## 8.15. PlantResourceObservation

Geometrija: `Point` ili `Polygon`.

Polja:

- `id`;
- `project_id`;
- `survey_visit_id`;
- `plant_taxon_id`;
- `resource_type`;
- `observed_at`;
- `geometry`;
- `abundance_class`;
- `patch_area_m2`;
- `phenology_stage`;
- `flowering_intensity`;
- `eggs_present`;
- `larvae_present`;
- `feeding_damage_present`;
- `photo_count`;
- `notes`;
- `created_by`;
- `created_at`;
- `updated_at`.

`resource_type`:

- `larval_host`;
- `nectar_source`;
- `oviposition_plant`;
- `resting_plant`;
- `unknown_association`.

## 8.16. HabitatFeature

Geometrija: `Point`, `LineString` ili `Polygon`.

Polja:

- `id`;
- `project_id`;
- `survey_visit_id`;
- `habitat_type_id`;
- `geometry`;
- `vegetation_height_cm`;
- `shrub_cover_pct`;
- `tree_cover_pct`;
- `bare_ground_pct`;
- `flower_abundance_class`;
- `management_type`;
- `grazing_intensity`;
- `mowing_status`;
- `disturbance_type`;
- `notes`;
- `created_at`;
- `updated_at`.

## 8.17. SensorStationLink

Polja:

- `id`;
- `project_id`;
- `name`;
- `sensorthings_thing_id`;
- `sensorthings_datastream_ids`;
- `geometry`;
- `active`;
- `metadata_json`.

## 8.18. EnvironmentalSnapshot

Ova tabela čuva vrednosti pridružene poseti ili nalazu kako bi analiza bila reproduktivna čak i ako se udaljeni servis kasnije promeni.

Polja:

- `id`;
- `survey_visit_id`;
- `observation_id`;
- `source_type`;
- `source_uri`;
- `retrieved_at`;
- `phenomenon_time`;
- `temperature_c`;
- `relative_humidity_pct`;
- `wind_speed_m_s`;
- `wind_direction_deg`;
- `cloud_cover_pct`;
- `precipitation_mm`;
- `solar_radiation_w_m2`;
- `raw_payload_json`.

`source_type`:

- `manual`;
- `sensorthings`;
- `edr`;
- `other_api`.

---

## 9. OGC mapiranje

## 9.1. OGC API – Features

Koristi se za objekte sa relativno stabilnom geometrijom ili diskretne prostorne nalaze:

- transekti;
- sekcije transekata;
- opažanja leptira;
- nalazi biljaka;
- stanišni objekti;
- senzorske stanice;
- zaštićena područja;
- administrativne ili projektne granice.

Predložene kolekcije:

- `/collections/transects`;
- `/collections/transect-sections`;
- `/collections/butterfly-observations`;
- `/collections/plant-resources`;
- `/collections/habitat-features`;
- `/collections/sensor-stations`.

Važno: osnovni OGC API – Features je prvenstveno standard za pronalaženje i čitanje geoprostornih objekata. Kreiranje i izmena podataka treba da se realizuju samo preko servera i ekstenzije koja zaista podržava transakcije, ili preko posebnog aplikacionog REST endpoint-a. Ne treba pretpostaviti da svaki Features server automatski podržava upis.

## 9.2. OGC SensorThings API

Predloženo mapiranje:

- `Thing`: mikroklimatska stanica ili uređaj;
- `Location`: mesto postavljanja uređaja;
- `Sensor`: konkretni senzor ili tip instrumenta;
- `ObservedProperty`: temperatura, vlažnost, osunčanost, brzina vetra;
- `Datastream`: vremenska serija jedne merene veličine;
- `Observation`: pojedinačno merenje;
- `FeatureOfInterest`: lokalitet ili mikro-stanište na koje se merenje odnosi.

Primer:

- Thing: „Stanica T01 — suva livada“;
- Sensor: „Senzor temperature vazduha“;
- ObservedProperty: „Air temperature“;
- Datastream: „T01 air temperature, 10 min“;
- Observation: 27.4 °C u 11:20;
- FeatureOfInterest: poligon ili tačka staništa T01.

## 9.3. OGC API – Moving Features

Koristi se samo za eksperimentalno praćenje jedinke.

Moving feature predstavlja jednu praćenu jedinku ili jednu sesiju praćenja. Putanja sadrži:

- vremenski uređene koordinate;
- vreme;
- brzinu;
- smer;
- opciono stanje ili ponašanje.

Događaji na putanji:

- sletanje;
- hranjenje;
- odmor;
- teritorijalno ponašanje;
- polaganje jaja;
- prelazak puta;
- ulazak u drugi tip staništa;
- gubitak jedinke iz vida.

Ovaj modul mora jasno beležiti da je putanja zasnovana na položaju posmatrača ili ručno procenjenom položaju leptira, osim ako se koristi namenski uređaj. Preciznost telefonskog GPS-a može biti nedovoljna za fina kretanja na maloj površini.

## 9.4. OGC API – EDR

EDR se koristi za prostorno-vremenske upite nad atmosferskim ili drugim kontinuiranim podacima.

Primeri upita:

- vremenski podaci za tačku transekta u trenutku posete;
- vremenski podaci duž transekta;
- vremenski podaci za određeni poligon i period;
- vremenska serija za lokalitet tokom sezone.

EDR treba tretirati kao dodatni izvor podataka. Ručno zabeleženi terenski uslovi i lokalni senzori imaju prednost za neposredne mikroklimatske uslove.

---

## 10. Server Architecture

Predložene komponente:

1. **Flutter mobilna aplikacija**
2. **Aplikacioni API**
3. **pygeoapi**
4. **FROST-Server**
5. **PostgreSQL**
6. **PostGIS**
7. **MobilityDB**, samo ako je potreban Moving Features modul
8. **Objektno skladište** za fotografije, npr. MinIO
9. **Reverse proxy**, npr. Nginx ili Traefik
10. **Docker Compose**
11. **Servis za autentikaciju**, ugrađen ili poseban

### 10.1. Preporučena podela odgovornosti

**Aplikacioni API**:

- autentikacija;
- autorizacija;
- poslovna pravila;
- unos i izmena podataka;
- sinhronizacija;
- konflikti;
- upload fotografija;
- validacija;
- zaključavanje poseta;
- audit log.

**pygeoapi**:

- standardizovano izlaganje geoprostornih kolekcija;
- pretraga i preuzimanje prostornih podataka;
- EDR, ako se implementira;
- Moving Features, ako odabrana ekstenzija bude stabilna i kompatibilna.

**FROST-Server**:

- SensorThings model;
- uređaji;
- senzori;
- datastream-ovi;
- observations;
- MQTT, ako postoji realna potreba za podacima u realnom vremenu.

**PostgreSQL/PostGIS**:

- centralno skladište aplikacionih i prostornih podataka.

**MobilityDB**:

- vremensko-prostorni tipovi i upiti za putanje;
- uvodi se tek kada osnovni modul radi.

**MinIO ili drugo objektno skladište**:

- fotografije i drugi veliki fajlovi.

### 10.2. Važna napomena o jednoj bazi

Moguće je da više servisa koristi isti PostgreSQL server, ali nije preporučljivo da svi direktno upisuju u iste tabele bez jasno definisanog vlasništva nad šemama.

Predlog:

- `app` šema — aplikacioni API;
- `geo` šema — prostorne kolekcije;
- `sensorthings` šema — FROST;
- `mobility` šema — putanje;
- `audit` šema — istorija promena.

„Single Source of Truth“ treba da znači jedinstven konzistentan sistem podataka, a ne nekontrolisano direktno pisanje više servisa u iste tabele.

---

## 11. Mobile Application

## 11.1. Predložene tehnologije

- Flutter;
- `flutter_map`;
- Drift;
- SQLite;
- background location paket;
- kamera i lokalni fajl sistem;
- HTTP klijent sa retry mehanizmom;
- secure storage za tokene;
- GeoJSON podrška;
- lokalni tile cache ili MBTiles za offline mapu.

Tačan izbor Flutter paketa treba potvrditi prototipom i proverom održavanja paketa.

## 11.2. Glavni ekrani

### A. Prijava

- email i lozinka;
- osvežavanje tokena;
- opciono biometrijsko otključavanje lokalnih podataka;
- prikaz poslednje uspešne sinhronizacije.

### B. Lista projekata

Za svaki projekat:

- naziv;
- period;
- broj preuzetih transekata;
- broj neposlatih promena;
- status offline paketa.

### C. Početni ekran projekta

Kartice:

- započni posetu;
- transekti;
- slobodni nalaz;
- biljke i staništa;
- mapa;
- nesinhronizovani podaci;
- validacija;
- statistika.

### D. Lista transekata

- naziv i kod;
- udaljenost od trenutne lokacije;
- poslednja poseta;
- broj poseta;
- preuzet offline;
- status;
- filter po području.

### E. Detalj transekta

- mapa;
- dužina;
- sektori;
- opis staništa;
- protokol;
- istorija poseta;
- dugme „Započni posetu“.

### F. Forma pre početka posete

- posmatrač;
- broj posmatrača;
- temperatura;
- vetar;
- oblačnost;
- padavine;
- procena uslova;
- napomena;
- potvrda protokola.

### G. Aktivna poseta

Glavni prikaz:

- mapa;
- trasa transekta;
- trenutna lokacija;
- pređena ruta;
- vreme posete;
- udaljenost;
- trenutni sektor;
- broj zabeleženih nalaza;
- veliko dugme „Dodaj leptira“;
- dugme „Dodaj biljku“;
- dugme „Dodaj stanište“;
- pauza;
- završi posetu.

Forma za novi nalaz mora biti brza. Cilj je da se čest nalaz unese za nekoliko sekundi.

### H. Brzi unos leptira

Prvi nivo:

- poslednje korišćene vrste;
- omiljene vrste;
- pretraga;
- broj jedinki;
- sačuvaj.

Drugi nivo, opciono:

- pol;
- stadijum;
- ponašanje;
- fotografija;
- biljka;
- pouzdanost;
- komentar.

GPS i vreme se automatski popunjavaju.

### I. Unos biljke

- vrsta biljke;
- odnos prema leptiru;
- tačka ili poligon;
- brojnost;
- površina;
- fenofaza;
- cvetanje;
- jaja;
- larve;
- fotografija;
- beleška.

### J. Završetak posete

Prikaz:

- trajanje;
- pređena udaljenost;
- broj vrsta;
- broj jedinki;
- upozorenja;
- nedostajuća obavezna polja;
- završni vremenski podaci;
- potvrda nultog nalaza, ako nema nalaza;
- dugme „Završi i sačuvaj“.

### K. Mapa

Slojevi:

- transekti;
- sektori;
- opažanja;
- biljke;
- staništa;
- senzorske stanice;
- ruta posete;
- zaštićena područja;
- offline bazna mapa.

Filteri:

- projekat;
- vrsta;
- datum;
- poseta;
- životni stadijum;
- ponašanje;
- validator status;
- tip staništa.

### L. Sinhronizacija

Prikaz:

- broj lokalnih promena;
- broj fotografija za upload;
- poslednja sinhronizacija;
- greške;
- konflikti;
- ponovno slanje;
- veličina prenosa.

---

## 12. Offline Mode

Offline rad je ključna funkcionalnost, a ne dodatak.

## 12.1. Lokalno se čuvaju

- projekti;
- korisničke dozvole;
- transekti;
- sektori;
- taksonomski šifarnik;
- šifarnici ponašanja i staništa;
- lokalne posete;
- rute;
- opažanja;
- biljke;
- staništa;
- fotografije;
- red za sinhronizaciju;
- poslednja poznata serverska verzija zapisa;
- offline mapa.

## 12.2. Lokalni identifikatori

Klijent treba da generiše UUID identifikatore. Time nalaz može postojati offline i kasnije biti poslat bez promene primarnog ključa.

## 12.3. Sync queue

Svaka promena ulazi u red:

- `entity_type`;
- `entity_id`;
- `operation`;
- `payload`;
- `created_at`;
- `retry_count`;
- `last_error`;
- `sync_status`.

Operacije:

- `create`;
- `update`;
- `delete`;
- `upload_attachment`.

## 12.4. Konflikti

Svaki zapis treba da ima:

- `updated_at`;
- `server_version`;
- opciono `etag`.

Predložena pravila:

- novi lokalni zapis bez serverske kopije — kreira se;
- serverski zapis nije menjan od preuzimanja — lokalna izmena se prihvata;
- i server i klijent su menjali zapis — konflikt;
- zaključana poseta ne može se menjati bez posebne dozvole;
- fotografije se deduplikuju preko SHA-256 vrednosti.

Za MVP konflikti mogu da se rešavaju ručno u administratorskom interfejsu. Ne koristiti nekritički „last write wins“ za biološke podatke.

---

## 13. Validation and Quality Control

## 13.1. Validacija pri unosu

Primeri pravila:

- broj jedinki mora biti najmanje 1;
- opažanje mora imati vreme i geometriju;
- opažanje u transektu mora pripadati aktivnoj poseti;
- vreme opažanja mora biti unutar perioda posete, uz malu toleranciju;
- fotografija može biti obavezna za određene vrste;
- vrste van poznatog područja mogu izazvati upozorenje;
- ekstremno loša GPS preciznost izaziva upozorenje;
- ponašanje `oviposition` treba da ponudi povezivanje sa biljkom;
- stadijum `larva` treba da ponudi biljku hraniteljku;
- završena poseta mora imati početne i završne vremenske podatke ili razlog za izostanak.

## 13.2. Automatske zastavice

- lokacija van projektnog područja;
- nalaz predaleko od transekta;
- duplirani nalaz u kratkom vremenu;
- neuobičajeno velika brojnost;
- retka vrsta;
- fenološki neuobičajen datum;
- identifikacija bez fotografije;
- nedovoljna pokrivenost transekta;
- prevelika prosečna brzina hodanja;
- prekid GPS zapisa;
- nepovoljni vremenski uslovi.

Zastavica nije automatsko odbacivanje podatka.

## 13.3. Audit log

Čuvati:

- ko je kreirao zapis;
- ko ga je izmenio;
- kada;
- prethodnu vrednost;
- novu vrednost;
- razlog izmene;
- validacionu odluku.

---

## 14. API dizajn aplikacionog sloja

Predloženi endpoint-i:

### Autentikacija

- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`

### Projekti

- `GET /projects`
- `GET /projects/{id}`
- `GET /projects/{id}/offline-package`

### Transekti

- `GET /projects/{id}/transects`
- `GET /transects/{id}`
- `GET /transects/{id}/visits`

### Posete

- `POST /survey-visits`
- `GET /survey-visits/{id}`
- `PATCH /survey-visits/{id}`
- `POST /survey-visits/{id}/complete`
- `POST /survey-visits/{id}/lock`

### Opažanja

- `POST /observations`
- `GET /observations/{id}`
- `PATCH /observations/{id}`
- `DELETE /observations/{id}`

### Biljke i staništa

- `POST /plant-resources`
- `PATCH /plant-resources/{id}`
- `POST /habitat-features`
- `PATCH /habitat-features/{id}`

### Fotografije

- `POST /attachments/init`
- `PUT /attachments/{id}/content`
- `POST /attachments/{id}/complete`

### Sinhronizacija

- `POST /sync/push`
- `POST /sync/pull`
- `GET /sync/status`
- `GET /sync/conflicts`
- `POST /sync/conflicts/{id}/resolve`

### Validacija

- `GET /validation/queue`
- `POST /observations/{id}/validate`

API treba dokumentovati kroz OpenAPI 3 specifikaciju.

---

## 15. Data Export

Obavezni formati:

- CSV;
- GeoJSON;
- GeoPackage, ako je praktično;
- JSON;
- opcioni Darwin Core kompatibilan izvoz.

Minimalni CSV skupovi:

1. `survey_visits.csv`
2. `butterfly_observations.csv`
3. `transects.csv`
4. `plant_resources.csv`
5. `habitat_features.csv`
6. `environmental_snapshots.csv`
7. `validation_history.csv`

Izvoz mora zadržati:

- stabilne ID vrednosti;
- koordinatni sistem;
- vreme sa vremenskom zonom;
- kod nedostajuće vrednosti;
- verziju protokola;
- verziju taksonomskog šifarnika;
- status validacije;
- terenski napor.

---

## 16. Osnovni indikatori u aplikaciji

Za svaki transekt ili period:

- broj poseta;
- ukupno trajanje posmatranja;
- ukupna pređena udaljenost;
- broj vrsta;
- broj jedinki;
- broj nalaza;
- broj potvrđenih nalaza;
- broj nalaza za proveru;
- broj poseta bez nalaza;
- broj opažanja po vrsti;
- brojnost po kilometru;
- brojnost po satu;
- datum prvog i poslednjeg nalaza;
- nedeljna ili mesečna fenologija;
- broj opažanja po ponašanju;
- broj reproduktivnih nalaza;
- broj vrsta povezanih sa biljkama hraniteljkama.

Napredna statistika nije neophodna u mobilnoj aplikaciji. Glavna analiza može se raditi u R-u.

---

## 17. Proposed Pilot Study

Realističan pilot:

- 3–5 transekata;
- 2–4 tipa staništa;
- 5–10 ponovljenih poseta po transektu;
- jedan deo sezone;
- svi zabeleženi leptiri;
- detaljnija obrada 2–3 fokalne vrste;
- kartiranje najmanje nekoliko važnih biljaka hraniteljki;
- najmanje jedna mikroklimatska stanica, ako je dostupna.

Predložene kategorije fokalnih vrsta:

- česta generalistička vrsta;
- stanišni specijalista;
- vrsta vezana za jasno prepoznatljivu biljku hraniteljku;
- opciono migratorna ili konzervaciono značajna vrsta.

Konačne vrste treba izabrati prema lokalnoj fauni i periodu terenskog rada.

---

## 18. Development Phases

## Faza 0 — Definisanje zahteva

Isporuke:

- finalni protokol;
- lista obaveznih i opcionih polja;
- šifarnici;
- početni ER dijagram;
- definicija MVP-a;
- kriterijumi uspeha.

Biolog i developer zajedno prolaze kroz jedan simulirani terenski dan.

## Faza 1 — Tehnički proof of concept

Cilj:

- Flutter aplikacija otvara mapu;
- prikazuje jedan transekt;
- lokalno kreira opažanje;
- čuva ga u Drift/SQLite;
- šalje ga na testni API;
- server ga čuva u PostGIS-u;
- podatak se prikazuje kroz OGC API – Features.

Ova faza treba da potvrdi arhitekturu pre razvoja svih formi.

## Faza 2 — MVP terenskog monitoringa

Implementirati:

- autentikaciju;
- projekte;
- transekte;
- posete;
- GPS rutu;
- brzi unos leptira;
- offline bazu;
- sync queue;
- osnovnu mapu;
- završavanje posete;
- CSV/GeoJSON izvoz.

## Faza 3 — Biološki resursi i kvalitet

Implementirati:

- biljke hraniteljke;
- nektarske biljke;
- stanišne objekte;
- fotografije;
- identifikacionu sigurnost;
- validacioni tok;
- automatske zastavice;
- audit log.

## Faza 4 — SensorThings

Implementirati:

- FROST-Server;
- registraciju stanice;
- jedan ili više datastream-ova;
- preuzimanje merenja;
- pridruživanje merenja poseti;
- lokalni environmental snapshot.

## Faza 5 — EDR i Moving Features

Samo nakon stabilnog MVP-a:

- EDR prototip;
- upit za jednu tačku i period;
- kratka focal-follow sesija;
- Moving Features putanja;
- prikaz putanje i događaja.

## Faza 6 — Pilot i evaluacija

- terensko testiranje;
- beleženje grešaka;
- poređenje papirnog i digitalnog unosa;
- procena vremena unosa;
- procena potpunosti podataka;
- procena uspeha sinhronizacije;
- anketa korisnika;
- finalna dokumentacija.

---

## 19. MVP Acceptance Criteria

MVP je uspešan kada:

1. korisnik može offline da preuzme projekat i transekte;
2. može da započne posetu bez interneta;
3. aplikacija beleži GPS rutu;
4. može da unese najmanje 50 opažanja bez gubitka podataka;
5. može da doda fotografije;
6. može da završi posetu i potvrdi nulti nalaz;
7. podaci ostaju sačuvani nakon gašenja aplikacije;
8. sinhronizacija se nastavlja nakon prekida veze;
9. dupli upload ne kreira duple zapise;
10. server čuva geometriju, vreme i biološke atribute;
11. prostorni podaci mogu da se dobiju preko OGC API – Features;
12. podaci mogu da se izvezu u CSV i GeoJSON;
13. zaključana poseta ne može slučajno da se izmeni;
14. promena determinacije ostaje zabeležena u audit istoriji.

---

## 20. System Evaluation

## 20.1. Funkcionalna evaluacija

Proveriti:

- da li su svi planirani tokovi izvršivi;
- da li aplikacija radi bez mreže;
- da li se podaci uspešno sinhronizuju;
- da li OGC klijenti mogu da pristupe kolekcijama;
- da li su podaci interoperabilni sa QGIS-om i skriptama.

## 20.2. Evaluacija kvaliteta podataka

Meriti:

- procenat kompletnih zapisa;
- procenat zapisa sa validnom geometrijom;
- broj duplikata;
- broj neuspešnih sinhronizacija;
- broj zapisa koji zahtevaju korekciju;
- procenat opažanja sa fotografijom;
- procenat potvrđenih determinacija;
- broj pravih nultih poseta.

## 20.3. Evaluacija upotrebljivosti

Moguće metrike:

- prosečno vreme unosa jednog nalaza;
- broj dodira potreban za čest nalaz;
- vreme potrebno za započinjanje posete;
- stopa grešaka;
- System Usability Scale;
- kratki polustrukturisani intervju sa biolozima.

## 20.4. Evaluacija performansi

Testirati:

- vreme učitavanja mape;
- vreme lokalnog upisa;
- vreme sinhronizacije;
- potrošnju baterije;
- rast lokalne baze;
- upload fotografija;
- ponašanje sa velikim brojem tačaka;
- server response time.

---

## 21. Risks and Mitigation

### Prevelik obim

**Rizik:** pokušaj implementacije svih standarda i funkcija.

**Mera:** zaključati MVP; EDR i Moving Features ostaviti kao dodatak.

### Nestabilna ili nedovoljno zrela ekstenzija

**Rizik:** mf-api ili integracija sa pygeoapi-jem ne radi kako je očekivano.

**Mera:** napraviti rani proof of concept; zadržati mogućnost čuvanja putanje u PostGIS/MobilityDB i izlaganja kroz aplikacioni API.

### GPS preciznost

**Rizik:** fina kretanja leptira ne mogu pouzdano da se mere telefonom.

**Mera:** Moving Features koristiti kao demonstracioni modul; čuvati preciznost; jasno dokumentovati metod.

### Baterija

**Rizik:** često GPS beleženje i kamera troše bateriju.

**Mera:** prilagodljiv interval; testirati background tracking; opcioni battery-saving režim.

### Loša mreža

**Rizik:** prekid upload-a i duplikati.

**Mera:** offline-first; idempotentni API; UUID; retry; checksum fotografija.

### Taksonomske promene

**Rizik:** promena prihvaćenih naziva.

**Mera:** verzionisan šifarnik; accepted-name relacije; ne menjati istorijski unos bez traga.

### Osetljivi nalazi

**Rizik:** javno izlaganje tačnih lokacija retkih vrsta.

**Mera:** role-based pristup; generalizovane javne koordinate; privatne precizne koordinate; audit pristupa.

### Više servisa nad bazom

**Rizik:** nekonzistentni upisi.

**Mera:** jasno vlasništvo nad šemama i tabelama; upis preko kontrolisanih API-ja.

---

## 22. Security and Privacy

- HTTPS;
- kratkotrajni access token;
- refresh token u secure storage-u;
- role-based kontrola;
- ograničenje projekata po korisniku;
- enkripcija rezervnih kopija;
- logovanje administrativnih akcija;
- uklanjanje EXIF lokacije iz javno dostupnih fotografija;
- ograničavanje preciznosti lokacija osetljivih vrsta;
- politika čuvanja i brisanja naloga;
- redovne rezervne kopije;
- test obnavljanja baze.

---

## 23. Docker Compose servisi

Primer logičkih servisa:

- `mobile-api`;
- `pygeoapi`;
- `frost`;
- `postgres`;
- `minio`;
- `reverse-proxy`;
- opciono `worker`;
- opciono `mqtt-broker`;
- opciono `admin-ui`.

Za razvoj se mogu koristiti:

- jedan PostgreSQL kontejner;
- odvojene šeme;
- persistent volumes;
- health checks;
- inicijalizacione migracije;
- `.env` konfiguracija;
- odvojeni development i production compose fajlovi.

Nikada ne čuvati produkcione lozinke u Git repozitorijumu.

---

## 24. Predložena struktura repozitorijuma

```text
butterfly-monitoring/
├── mobile/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   ├── migrations/
│   ├── tests/
│   └── openapi/
├── pygeoapi/
│   ├── config/
│   └── plugins/
├── frost/
│   └── config/
├── database/
│   ├── init/
│   ├── seeds/
│   └── diagrams/
├── infrastructure/
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   └── proxy/
├── docs/
│   ├── biological-protocol.md
│   ├── data-dictionary.md
│   ├── architecture.md
│   ├── synchronization.md
│   └── field-manual.md
├── sample-data/
├── scripts/
├── .env.example
└── README.md
```

---

## 25. Required Documentation

1. arhitektonski dijagram;
2. ER dijagram;
3. rečnik podataka;
4. biološki terenski protokol;
5. OpenAPI specifikacija;
6. opis OGC kolekcija;
7. opis SensorThings mapiranja;
8. opis offline sinhronizacije;
9. korisničko uputstvo;
10. administratorsko uputstvo;
11. postupak instalacije;
12. postupak backup-a i restore-a;
13. plan testiranja;
14. rezultati pilot evaluacije;
15. poznata ograničenja.

---

## 26. Priorities

### Must have

- offline rad;
- projekti i transekti;
- standardizovane posete;
- unos leptira;
- GPS i vreme;
- terenski napor;
- fotografije;
- sinhronizacija;
- PostGIS;
- OGC API – Features;
- CSV/GeoJSON izvoz;
- validacija osnovnih polja.

### Should have

- biljke hraniteljke;
- stanišni objekti;
- ekspert validacija;
- automatske zastavice;
- SensorThings integracija;
- osnovna statistika;
- offline mapa.

### Could have

- EDR;
- Moving Features;
- MQTT real-time prikaz;
- napredni dashboard;
- automatsko prepoznavanje vrste sa fotografije;
- Darwin Core izvoz;
- javni portal.

### Ne treba uključiti u prvu verziju

- kompleksno mašinsko učenje;
- kompletan nacionalni sistem;
- automatsko određivanje vrste kao jedini metod;
- napredne ekološke statističke modele u mobilnoj aplikaciji;
- real-time tracking leptira bez odgovarajućeg uređaja;
- implementaciju svih OGC standarda od nule.

---

## 27. Key Decisions for the Biologist and Developer

1. Koji je tačan terenski protokol?
2. Koja polja moraju biti obavezna?
3. Da li se beleži svaka jedinka ili agregirani nalaz?
4. Kako se tretiraju grupni nalazi?
5. Koja je dozvoljena udaljenost nalaza od transekta?
6. Kako se definiše validna poseta?
7. Kako se beleži pravi nulti nalaz?
8. Koji šifarnik vrsta se koristi?
9. Ko može da promeni determinaciju?
10. Kako se štite lokacije osetljivih vrsta?
11. Da li se biljke mapiraju kao tačke, poligoni ili oba?
12. Koji vremenski podaci se beleže ručno?
13. Koji senzori stvarno postoje?
14. Da li je Moving Features potreban za odbranu rada ili samo za demonstraciju?
15. Koji deo sistema predstavlja originalni doprinos kandidata?

---

## 28. Proposed Original Scientific Contribution

Najrealističniji doprinos nije razvoj novog OGC standarda, već:

- dizajn biološki smislenog modela podataka za terenski monitoring leptira;
- integracija offline mobilnog rada sa standardizovanim geoprostornim servisima;
- povezivanje opažanja, terenskog napora, biljnih resursa i mikroklimatskih merenja;
- evaluacija interoperabilnosti;
- evaluacija kvaliteta podataka i upotrebljivosti sistema u realnim terenskim uslovima.

Predložena formulacija:

> Originalni doprinos rada predstavlja razvoj i evaluacija interoperabilnog, offline-first mobilnog GIS sistema koji objedinjuje standardizovane podatke o opažanjima dnevnih leptira, terenskom naporu, biljkama hraniteljkama, staništima i uslovima sredine kroz primenu OGC API standarda.

---

## 29. First Practical Task for the Team

Pre programiranja organizovati simulaciju jedne terenske posete:

1. izabrati postojeći ili nacrtati testni transekt;
2. odglumiti početak posete;
3. evidentirati deset zamišljenih nalaza;
4. evidentirati jednu biljku hraniteljku;
5. dodati fotografiju;
6. završiti posetu;
7. pokušati da podatke prebacite u jednu tabelu;
8. označiti svaki korak koji je bio spor, nejasan ili dvosmislen.

Na osnovu toga finalizovati forme i model podataka.

---

## 30. Official Technical References

- OGC API – Features: https://www.ogc.org/standards/ogcapi-features/
- OGC SensorThings API: https://www.ogc.org/standards/sensorthings/
- OGC API – Moving Features: https://www.ogc.org/standards/ogc-api-moving-features/
- OGC API – Environmental Data Retrieval: https://www.ogc.org/standards/ogcapi-edr/

Pre konačne implementacije proveriti aktuelne verzije pygeoapi-ja, FROST-Servera, MobilityDB-a, Flutter paketa i svih community ekstenzija, kao i njihovu međusobnu kompatibilnost.
