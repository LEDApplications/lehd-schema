#!/usr/bin/env bash

set -e

# Location of this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

############################################################
# Help                                                     #
############################################################
help() {
  # Display help
  echo "Generate the LEHD schema documentation"
  echo
  echo "Process and generate the official schema output"
  echo "Excluding binary files (shp, zip)."
  echo
  echo "Syntax: generate_schema_docs.sh [-p|h] [-v <version string>]"
  echo "options:"
  echo "h     Print this Help."
  echo "p     Generate PDF output alongside the html"
  echo "v     Generate schema with version number"
  echo
  echo "Example:"
  echo "./generate_schema_docs -v V1.2.3"
  echo
}

############################################################
# Process the input options. Add options as needed.        #
############################################################
# No arguments
if [[ $# -eq 0 ]]; then
  help
  exit 1
fi

# Parse arguments
while getopts ":hv:p" option; do
  case $option in
  h) # display help
    help
    exit 1
    ;;
  p) # generate PDF
    generate_pdf=true
    ;;
  v) # Enter a schema version
    version=$OPTARG ;;
  \?) # Invalid option
    echo "Error: invalid argument"
    echo
    help
    exit 1
    ;;
  esac
done

source_dir=${SCRIPT_DIR}/src
destination_dir=${SCRIPT_DIR}/dist
lib_dir=${SCRIPT_DIR}/lib

# Validate that there are no "bad" characters in the src csv files
# Source: 
# https://github.com/WengerK/vscode-highlight-bad-chars/blob/master/src/bad-characters.ts 
#
# Cannot check for \u characters directly in bash grep, so only check for \x
# grep: PCRE2 does not support \F, \L, \l, \N{name}, \U, or \u

bad_chars=(
    # https://github.com/possan/sublime_unicode_nbsp/blob/master/sublime_unicode_nbsp.py
    '\x82' # High code comma
    '\x84' # High code double comma
    '\x85' # Triple dot
    '\x88' # High carat
    '\x91' # Forward single quote
    '\x92' # Reverse single quote
    '\x93' # Forward double quote
    '\x94' # Reverse double quote
    '\x95' # <control> Message Waiting
    '\x96' # High hyphen
    '\x97' # Double hyphen
    '\x99' # <control>
    '\xA0' # No-break space
    '\xA6' # Split vertical bar
    '\xAB' # Double less than
    '\xBB' # Double greater than
    '\xBC' # one quarter
    '\xBD' # one half
    '\xBE' # three quarters
    '\xBF' # c-single quote
    '\xA8' # modifier - under curve
    '\xB1' # modifier - under line
    '\x00' # NUL

    # control characters
    '\x01' # SOH
    '\x02' # STX
    '\x03' # ETX
    '\x04' # EOT
    '\x05' # ENQ
    '\x06' # ACK
    '\x07' # BEL
    '\x08' # BS
    '\x0B' # VT
    '\x0C' # FF
    '\x0E' # SO
    '\x0F' # SI
    '\x10' # DLE
    '\x11' # DC1
    '\x12' # DC2
    '\x13' # DC3
    '\x14' # DC4
    '\x15' # NAK
    '\x16' # SYN
    '\x17' # ETB
    '\x18' # CAN
    '\x19' # EM
    '\x1A' # SUB
    '\x1B' # ESC
    '\x1C' # FS
    '\x1D' # GS
    '\x1E' # RS
    '\x1F' # US
    '\x7F' # DEL
)
 
# Generate the pattern for grep by concatenating the array elements
pattern=$(printf '[%s]' "$(IFS=; echo "${bad_chars[*]}")")

# List of files with bad characters
badfiles=""

for file in "$source_dir"/*.csv; do
  count=$(grep -oP "$pattern" "$file" | wc -l)

  # Output the result
  if [ "$count" -gt 0 ]; then
    # echo "Error: $count bad characters found in $file"
    badfiles="$badfiles $file"
  fi
done

if [ -n "$badfiles" ]; then
  echo "Error: Bad characters detected"
  echo "Please remove bad characters from these files and try again."
  for f in $badfiles; do
    echo "  $f"
  done
  exit 1
fi

# clean create output folder
rm -rf "$destination_dir"
mkdir "$destination_dir"

# get a listing of all the files linked in the asciidoc source
# egrep allows use of ? for non-greedy matching
# options: -o only include match, -h hide filenames,
# the .*? pattern uses a non-greedy match for instances where multiple files appear in a single line
# grep -v removes any entries that include the `ext-relative` text (aka, part of the docs themselves)
# also ignore any zip files as they're shapefiles from prod
# sed then trims instances of "link:some_file_name.csv[]" into "some_file_name.csv"
# sort -u dedupes the list
csvs_linked_in_asciidoc=$(egrep -ho "(link|include):.*?\.csv\[.*?\]" src/*.asciidoc |
                          grep -v '{ext-relative}' |
                          grep -v '.zip' |
                          grep -v '.asciidoc' |
                          sed 's/link://g' |
                          sed 's/include:://g' |
                          sed 's/\[.*\]$//g' |
                          sort -u)

# get a listing of csv files in the source dir and dedupe
csvs_in_src_dir=$(ls $source_dir | grep "\.csv" | sort -u)

# compare two files, suppress output from the 1st file (-1) and output that's matched (-3)
undocumented_files=$(comm -13 <(echo "$csvs_linked_in_asciidoc") <(echo "$csvs_in_src_dir"))

if [ -n "$undocumented_files" ]; then
  echo "Warn: the following files are not documented"
  echo "$undocumented_files"
  echo ""
fi

# compare two files, suppress output from the 2nd file (-2) and output that's matched (-3)
missing_files=$(comm -23 <(echo "$csvs_linked_in_asciidoc") <(echo "$csvs_in_src_dir"))
if [ -n "$missing_files" ]; then
  echo "Warn: the following files are documented but not in the source"
  echo "$missing_files"
  echo ""
fi

echo "Info: generating schema docs..."

# move into the src directory
cd "$source_dir" >/dev/null

# generate public schema doc
asciidoctor -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
  -a stylesheet="${lib_dir}/css/asciidoctor.css" \
  -a schemaversion=$version \
  -a outfilesuffix=.html \
  -o "${destination_dir}/lehd_public_use_schema.html" \
  --trace \
  lehd_public_use_schema.asciidoc

#asciidoctor -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
#  -a stylesheet="${lib_dir}/css/asciidoctor.css" \
#  -a schemaversion=$version \
#  -a outfilesuffix=.html \
#  -o "${destination_dir}/lehd_public_use_schema_qwi.html" \
#  lehd_public_use_schema_qwi.asciidoc

# generate the csv naming doc
asciidoctor -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
  -a stylesheet="${lib_dir}/css/asciidoctor.css" \
  -a schemaversion=$version \
  -a schemaversion=$version \
  -a outfilesuffix=.html \
  -o "${destination_dir}/lehd_csv_naming.html" \
  --trace \
  lehd_csv_naming.asciidoc

# generate shapefiles doc
asciidoctor -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
  -a stylesheet="${lib_dir}/css/asciidoctor.css" \
  -a schemaversion=$version \
  -a schemaversion=$version \
  -a outfilesuffix=.html \
  -o "${destination_dir}/lehd_shapefiles.html" \
  --trace \
  lehd_shapefiles.asciidoc

# generate changelog
asciidoctor -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
  -a stylesheet="${lib_dir}/css/asciidoctor.css" \
  -a schemaversion=$version \
  -a schemaversion=$version \
  -a outfilesuffix=.html \
  -o "${destination_dir}/lehd_changelog.html" \
  --trace \
  lehd_changelog.asciidoc

# generate PDF versions
if [ "$generate_pdf" = true ] ; then
  asciidoctor-pdf -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
    -a schemaversion=$version \
    -o "${destination_dir}/lehd_public_use_schema.pdf" \
    --trace \
    lehd_public_use_schema.asciidoc

#  asciidoctor-pdf -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
#    -a schemaversion=$version \
#    -o "${destination_dir}/lehd_public_use_schema_qwi.pdf" \
#    lehd_public_use_schema_qwi.asciidoc

  asciidoctor-pdf -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
    -a schemaversion=$version \
    -o "${destination_dir}/lehd_csv_naming.pdf" \
    --trace \
    lehd_csv_naming.asciidoc

  asciidoctor-pdf -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
    -a schemaversion=$version \
    -o "${destination_dir}/lehd_shapefiles.pdf" \
    --trace \
    lehd_shapefiles.asciidoc

  asciidoctor-pdf -r "${lib_dir}/csvsubcolumn-include-processor.rb" \
    -a schemaversion=$version \
    -o "${destination_dir}/lehd_changelog.pdf" \
    --trace \
    lehd_changelog.asciidoc
fi

# return to the root dir
cd - >/dev/null

echo "Info: done"
