# render two PDFs and combine into one PDF
library(quarto)
library(pdftools)
library(fs)
library(stringr)

file_name <- "2023H1_Elimisha"
file_cover <- paste0(file_name, "_cover") # cover
file_body <- paste0(file_name, "_body") # body

# render
quarto_render(paste0(file_cover,".qmd"), output_format = "titlepage-pdf")
quarto_render(paste0(file_body,".qmd"), output_format = "PrettyPDF-pdf")

tmp_pdf_filename <- file_temp(ext = "pdf")

# combine
pdf_combine(
  c(paste0(file_cover,".pdf"), paste0(file_body,".pdf")),
  output = tmp_pdf_filename
  )

# retrieve metadata from the 'body' PDF
# including Info (creator, author, title etc.)
# and also the Bookmarks
tmp_meta_in_filename <- file_temp(ext = ".txt")
tmp_meta_out_filename <- file_temp(ext = ".txt")
system(
  paste(
    "pdftk",
    paste0(file_body,".pdf"),
    "dump_data",
    "output",
    tmp_meta_in_filename
  )
)

add_one_to_number <- function(strings, start_characters) {
  # add one to the number at the end of the string if it starts with certain characters
  # find indices of strings that start with specified characters, and ends with a number
  indices <- grep(paste0("^", start_characters, ".*\\d+$"), strings)

  for (i in indices) {
    # find the number at the end of the string
    # 'back-reference' to the match with '\\1'
    pagenumber <- as.numeric(gsub(".*?(\\d+)$","\\1", strings[i]))
    pagenumber <- pagenumber + 1
    # replace just the pagenumber with the updated pagenumber
    strings[i] <- gsub("\\d+$", as.character(pagenumber), strings[i])
  }

  return(strings)
}

scan(tmp_meta_in_filename, what = character(), sep = '\n') |>
  # filter strings starting with 'Info' or 'Bookmark'
  str_subset("^Info|^Bookmark") |>
  # add one to pages in bookmarks
  # since the 'first' page (page number 1) will now be page 'i' in cover
  # the page with roman number '1' will be page 2 of the PDF
  add_one_to_number("BookmarkPageNumber") |>
  # renumber pages
  # first page (the cover page) is 'i', and second page is '1'
  # note that page numbers are shown correctly in evince and WPS,
  # but not programs like okular
  # and add information and bookmarks
  append(scan("pagerenumbering_metadata.txt", what = character(), sep = "\n")) |>
  write(
    file = tmp_meta_out_filename,
    append = FALSE,
    sep = "\n"
  )

system(
  paste(
    "pdftk",
    tmp_pdf_filename,
    "update_info",
    tmp_meta_out_filename,
    "output",
    paste0(file_name, ".pdf")
  )
)
