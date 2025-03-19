using Pkg


packages = [
    ("NCDatasets",      "0.14.6"),
    ("Geodesy",         "1.1.0"),
    ("GDAL",            "1.10.0"),
    ("LibGEOS",         "0.9.4"),
    ("GeoJSON",         "0.8.2"),
    ("Leaflet",         "0.1.1"),
    ("TileProviders",   "0.1.4"),
    ("ZarrDatasets",    "0.1.3")
]

for (name, version) in packages
    Pkg.add(Pkg.PackageSpec(name=name, version=version))
end
