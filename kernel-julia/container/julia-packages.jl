using Pkg


packages = [
    ("NCDatasets",      "0.14.6"),
    ("Geodesy",         "1.1.0"),
    ("GDAL",            "1.10.0"),
    ("LibGEOS",         "0.9.4"),
    ("GeoJSON",         "0.8.2"),
    ("Leaflet",         "0.1.1"),
        ("Blink",       "0.12.9"), # requires webio-jupyter-extension
        ("GADM",        "1.2.0"),
    ("TileProviders",   "0.1.4"),
    ("ZarrDatasets",    "0.1.3"),
    ("CSV",             "0.10.15"),
    ("DataFrames",      "1.7.0"),
    ("Plots",           "1.40.11"),
    ("PyCall",          "1.96.4"),
    #(<package name>, <version>)
]

for (name, version) in packages
    Pkg.add(Pkg.PackageSpec(name=name, version=version))
end

Pkg.precompile()
