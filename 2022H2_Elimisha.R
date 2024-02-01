# render two PDFs and combine into one PDF
library(quarto)
library(pdftools)
library(fs)

# render
quarto_render( "2022H2_Elimisha_cover.qmd", output_format = "titlepage-pdf")
quarto_render( "2022H2_Elimisha_body.qmd", output_format = "PrettyPDF-pdf")

tmp_pdf_filename <- file_temp(ext = "pdf")

# combine
pdf_combine(
  c("2022H2_Elimisha_cover.pdf", "2022H2_Elimisha_body.pdf"),
  output = tmp_pdf_filename
  )

# renumber pages
# first page (the cover page) is 'i', and second page is '1'
# note that page numbers are shown correctly in evince and WPS,
# but not programs like okular
system(
  paste(
    "pdftk",
    tmp_pdf_filename,
    "update_info pagerenumbering_metadata.txt",
    "output 2022H2_Elimisha.pdf"
  )
)