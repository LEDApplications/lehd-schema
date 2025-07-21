# Instructions

How to build the docs.

## Build the current version of the schema

1. Install or update asciidoctor

    ```shell
    # validate that the ruby 2.6 is the active version
    # if not, install and configure ruby on your path
    ruby --version
    which ruby
    
    # install packages
    gem install asciidoctor
    gem install asciidoctor-pdf

    # csv is not part of the default gems starting from Ruby 3.4.0.
    gem install csv 
    ```

2. Load the schema version from the environment variable

    ```shell
    # set the $SCHEMA_VERSION environment variable
    export $(xargs <.env)
    ```

3. Build the docs

    ```shell
    # html only
    ./generate_schema_docs.sh -v $SCHEMA_VERSION
    # html and pdf
    ./generate_schema_docs.sh -v $SCHEMA_VERSION -p
    ```

4. Deploy the output files

    ```shell
    # html, and pdf are in the ./dist directory
    cp ./dist /path/to/schemas/$SCHEMA_VERSION -r
    # csv files are in the ./src directory
    cp ./src/*.csv /path/to/schemas/$SCHEMA_VERSION
    # txt files
    cp ./src/*.txt /path/to/schemas/$SCHEMA_VERSION
    ```

5. Correct csv line endings

    ```shell
    cd /path/to/schemas/$SCHEMA_VERSION
    for f in $(ls *.csv); do echo processing ${f}...; dos2unix $f; done      
    ```

6. Add shapefiles (official deploy only)

    Official shapefiles for reference geographies should be deployed to the output directory. In some scenarios this can be as simple as copying the previous files from one schema to another.

    ```shell
    cd /path/to/schemas
    cp $OLD_SCHEMA_VERSION/*.zip $SCHEMA_VERSION/
    ```

    If a new set of geographies correspond to this schema version then they'll need to be sourced from the LEHD geoprocessing output files.

    > **Important**: Verify the shapefile/geography files match with the released schema version.

7. Add header (official deploy only)

    When deploying an official version there's an convenience header that can be added to the top of the html files. This is done by running the following command.

    ```shell
   cd /path/to/schemas/
   cp $OLD_SCHEMA_VERSION/HEADER.html $SCHEMA_VERSION/
   ```
