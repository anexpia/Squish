# Squish
*This is a fork of <b>[Squash](https://github.com/Data-Oriented-House/Squash)</b>.*

A simple but comprehensive SerDes library for Roblox, aimed at minimizing bandwidth and saving space by reducing the size of data. It is designed with the programmer in mind, offering full flexibility and control over the data being serialized and deserialized, with an intuitive api.

It expands upon Squash's design by adding more SerDes (e.g. variant, number, instances), exposing more utility functions for writing your own SerDes, and offering better performance in general.

Full list of changes are present [here](https://anexpia.github.io/Squish/docs/differences).

# Documentation
Documentation is present [here](https://anexpia.github.io/Squish).

# Installation

- **Manual**: Copy/paste the `src/init.luau` file.
- **Pesde**:
```bash
pesde add anexpia/squish
pesde install
```

- **Wally**:
Add to your `wally.toml` under `[dependencies]`:
```toml
Squish = "anexpia/squish@6.1.1"
```