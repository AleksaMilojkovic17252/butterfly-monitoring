# OGC interoperability evaluation (T070)

Evidence that standard clients can use the data published by pygeoapi. Results: [results.md](results.md).
All commands are fish, from the repository root. The token is a personal admin token (`docs/setup/ogc-access.md`);
scripts read it from the environment and never print it.

## Python notebook

```fish
python -m venv evaluation/.venv
evaluation/.venv/bin/pip install -r evaluation/requirements.txt
# One-off: the credential file, chmod 600. The notebook reads the token only from it (no environment variable)
printf 'Authorization: Token %s\n' <key> > ~/.ogc-header; chmod 600 ~/.ogc-header
evaluation/.venv/bin/jupyter lab evaluation/interop/ogc-clients.ipynb   # or open the notebook in VSCodium
```

Run all cells and save the notebook with its outputs. Check that the token is not in it: `grep -c "Token " evaluation/interop/ogc-clients.ipynb` should only count code lines.

## R

```fish
sudo pacman -S r   # sf (and so gdal, geos, proj, udunits) is not needed: the script uses httr2 and ggplot2
mkdir -p ~/.local/share/R/library; set -x R_LIBS_USER ~/.local/share/R/library   # /usr/lib/R/library is not writable
Rscript -e 'install.packages(c("httr2","jsonlite","ggplot2"), lib=Sys.getenv("R_LIBS_USER"), repos="https://cloud.r-project.org")'
env OGC_KEY=<key> Rscript evaluation/interop/phenology.R   # with R_LIBS_USER still set
```

Writes `evaluation/interop/phenology.png` and prints rows read and `numberMatched`.

## QGIS

Steps and screenshot names: see the checklist in `results.md`. Connection setup: `docs/setup/ogc-access.md` § QGIS.

## OGC CITE (`ets-ogcapi-features10`, TEAM Engine)

The `test` compose profile holds a second pygeoapi (`pygeoapi-cite`, links point at itself, no nginx, no auth) and the
suite (`ets-features`, `http://localhost:8081/teamengine`). A plain `up` starts neither.

```fish
set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml
$DC --profile test up -d pygeoapi-cite ets-features        # the suite needs about 30 s to start
set U 'http://localhost:8081/teamengine/rest/suites/ogcapi-features-1.0/run?iut=http%3A%2F%2Fpygeoapi-cite%3A5000%2Fogc&noofcollections=-1'
curl -s -u ogctest:ogctest -H 'Accept: application/xml' -o evaluation/interop/cite/testng-results.xml $U
curl -s -u ogctest:ogctest -H 'Accept: application/rdf+xml' -o evaluation/interop/cite/earl.rdf $U
python3 -I evaluation/interop/cite/make_report.py evaluation/interop/cite/testng-results.xml evaluation/interop/cite/report.html
$DC --profile test stop pygeoapi-cite ets-features
```

`noofcollections=-1` tests all collections (the default is 3). TEAM Engine REST answers XML and EARL only (`text/html` gives 406),
so `report.html` is a summary built from the XML by `evaluation/interop/cite/make_report.py`. `testng-results.xml` is gitignored (3.4 MB, regenerable); `earl.rdf` and `report.html` are kept.
