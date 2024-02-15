suppressMessages(suppressWarnings(library('spatialGE')))
suppressMessages(suppressWarnings(library('optparse')))
source('/usr/local/bin/prep_stlist.R')

# args from command line:
args <- commandArgs(TRUE)

# note, -k --kclusters can be integer or character ('dtc') for valid options
option_list <- list(
    make_option(
        c('-f', '--input_file'),
        help='Path to the count matrix input.'
    ),
    make_option(
        c('-c', '--coordinates_file'),
        help='Path to the barcode spatial coordinates input.'
    ),
    make_option(
        c('-s', '--sample_name'),
        help='Sample name'
    ),
    make_option(
        c('-n', '--normalization'),
        help='Normalization method of `log` or `SCTransform`'
    ),
    make_option(
        c('-o','--output_file_prefix'),
        help='The prefix for the output file'
    )
)

opt <- parse_args(OptionParser(option_list=option_list))

# Check that the file was provided:
# Checks are incomplete
if (is.null(opt$input_file)){
    message('Need to provide a count matrix with the -f/--input_file arg.')
    quit(status=1)
}

if (is.null(opt$coordinates_file)){
    message('Need to provide a count matrix with the -c/--coordinates_file arg.')
    quit(status=1)
}

# transform the name of the normalization scheme:
if (is.null(opt$normalization)){
    message('Need to provide a normalization scheme with the -n/--normalization arg.')
    quit(status=1)
} else if(tolower(opt$normalization) == 'sctransform'){
    norm_scheme <- 'sct'
} else if(tolower(opt$normalization) == 'log'){
    norm_scheme <- 'log'
} else {
    message('We only accept `log` or `SCTransform` for the normalization scheme.')
    quit(status=1)
}

# change the working directory to co-locate with the counts file:
working_dir <- dirname(opt$input_file)
setwd(working_dir)

# call the utility function which will return a list with the necessary items:
spat_list <- prep_stlist(opt$input_file, opt$coordinates_file, opt$sample_name)

# unpack:
colname_mapping <- spat_list$colname_mapping
spat <- spat_list$spat

# Transform the data
spat <- transform_data(spat, method=norm_scheme)

# Export of the normalized data to full matrix flat file
# Note: we could convert to a .h5
df <- data.frame(
    as.matrix(spat@tr_counts[[opt$sample_name]])
)

# now convert the rownames back:
remapped_cols = colname_mapping[colnames(df), 'orig_names']
colnames(df) = remapped_cols

if (is.null(opt$output_file_prefix)) {
    output_filename <- sprintf('%s/%s.spatialge_normalized.%s.tsv', working_dir, opt$sample_name, opt$normalization)
} else {
    output_filename <- sprintf('%s/%s.%s.spatialge_normalized.%s.tsv', working_dir, opt$sample_name, opt$output_file_prefix, opt$normalization)
}
write.table(
    df,
    file=output_filename,
    sep="\t", quote=F, row.names=T
)

json_str = paste0('{"normalized_expression":"', output_filename, '"}')
output_json <- paste(working_dir, 'outputs.json', sep='/')
write(json_str, output_json)