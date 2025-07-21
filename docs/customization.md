# Customization

This document describes any non-standard features of the build system.

## Tracking

Adding the adobe tracking information to the schema is done through [docinfo](https://docs.asciidoctor.org/asciidoc/latest/docinfo/) files.
Additional scripts can be added to the `docinfo.html` file in the which will be included in the generated HTML.

## Asciidoctor Extensions

### CsvSubcolumnIncludeProcessor

The LEHD schema files can include many rows and columns that don't need to appear directly in the output documents. To this end the [asciidoctor maintainers recommend using a custom include processor](https://github.com/asciidoctor/asciidoctor/issues/2101) that allow for subsetting columns of the original csv. A [community developed plugin](https://github.com/yugp2005/Asciidoctor-CSV-SubColumn) was developed to this end however it doesn't allow for subsetting by both rows and columns. This repository builds on that plugin to allow for both.

The ruby extension `csvsubcolumn-include-processor.rb` is contained in the `lib/` directory and allows a csv include to be used as follows.

#### Loading the extension

This is automatically done in `generate_schema_docs.sh` but if needed the extension can be loaded into asciidoctor as follows.

```shell
asciidoctor -r ./lib/csvsubcolumn-include-processor.rb somefile.asciidoc
```

#### Include Preprocessor Usage

A custom csv plugin allows the subsetting of rows and columns directly in asciidoc files.

- Include specific lines: `lines=1;3;5;7;`
- Include specific columns: `columns=1;3;5;7;`
- Include line ranges: `lines=1..3;5..7;`
- Include column ranges: `columns=1..3;5..7;`
- Mix and match: `lines=1;5..7;,columns=1;3..7;`

##### Include only select lines

```asciidoc
include::label_industry.csv[lines=1..8;]
```

##### Include select columns

```asciidoc
include::label_geo_level.csv[columns=1..3]
```

##### Include select rows and columns

```asciidoc
include::variables_qwiv.csv[lines=1..4;,columns=1;3..4;]
```
