/// True when a GPS fix counts for a route (D-060): its accuracy is not worse
/// than twice [gpsAccuracyWarningM]. A fix without an accuracy is kept. The
/// server uses the same rule for `distance_walked_m`, T100 for the coverage and
/// T108 for a route proposal's line.
bool isUsableAccuracy(double? accuracyM, double gpsAccuracyWarningM) {
  return accuracyM == null || accuracyM <= 2 * gpsAccuracyWarningM;
}
