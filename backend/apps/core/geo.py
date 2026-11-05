"""Small geometry helpers shared by apps. A leaf module: it imports nothing from the apps."""


def utm_srid(geometry):
    """EPSG code of the WGS 84 UTM zone that holds the centre of a 4326 geometry."""
    centre = geometry.centroid
    zone = int((centre.x + 180) // 6) % 60 + 1
    return (32600 if centre.y >= 0 else 32700) + zone
