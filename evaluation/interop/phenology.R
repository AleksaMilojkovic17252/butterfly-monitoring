# T070: read butterfly observations from the OGC API with httr2, plot a phenology chart.
# Run: env OGC_KEY=<key> Rscript evaluation/interop/phenology.R   (from the repository root)
library(httr2)
library(ggplot2)

base <- Sys.getenv("OGC_BASE", "http://localhost:8080/ogc")
key <- Sys.getenv("OGC_KEY")
if (key == "") stop("Set OGC_KEY to a personal token (docs/setup/ogc-access.md)")

url <- paste0(base, "/collections/butterfly-observations/items")
query <- list(f = "json", limit = 1000, sortby = "id")
rows <- list()
matched <- NA
pages <- 0
repeat {
  req <- request(url) |> req_headers(Authorization = paste("Token", key))
  if (!is.null(query)) req <- req_url_query(req, !!!query)
  body <- req |> req_perform() |> resp_body_json()
  pages <- pages + 1
  matched <- body$numberMatched
  rows <- c(rows, lapply(body$features, function(f) {
    p <- f$properties
    data.frame(
      observed_at = p$observed_at,
      effective_scientific_name = p$effective_scientific_name,
      count = if (is.null(p$count)) NA_integer_ else p$count,
      stringsAsFactors = FALSE
    )
  }))
  nxt <- Filter(function(l) l$rel == "next", body$links)
  if (length(nxt) == 0) break
  url <- nxt[[1]]$href
  query <- NULL # the next link carries every parameter
}
obs <- do.call(rbind, rows)
cat("rows read:", nrow(obs), "| numberMatched:", matched, "| pages:", pages, "\n")

# observed_at is "2026-06-01T09:26:50+00:00" (UTC); strip the offset, weeks are ISO weeks of the UTC time.
# (The server's report views use the project time zone, so a week can differ at midnight.)
obs$week <- as.integer(format(as.POSIXct(substr(obs$observed_at, 1, 19), format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"), "%V"))
totals <- aggregate(count ~ effective_scientific_name, obs, sum)
top <- head(totals[order(-totals$count), "effective_scientific_name"], 6)
weekly <- aggregate(count ~ effective_scientific_name + week, obs[obs$effective_scientific_name %in% top, ], sum)

p <- ggplot(weekly, aes(week, count)) +
  geom_col(fill = "darkorange") +
  facet_wrap(~effective_scientific_name, scales = "free_y") +
  labs(x = "ISO week", y = "Individuals", title = "Phenology of the 6 most numerous species (simulated season)") +
  theme_minimal()
ggsave("evaluation/interop/phenology.png", p, width = 10, height = 6, dpi = 150)
cat("saved evaluation/interop/phenology.png\n")
