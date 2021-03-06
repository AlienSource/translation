# problem loading rJava, http://stackoverflow.com/a/9120712
Sys.setenv(JAVA_HOME='C:\\Program Files\\Java\\jdk1.7.0_75\\jre')
require(XLConnect)
# needed for cpos functions
require(cwhmisc)

LoadTranslationAndCreateSummarySheet <- function(file.dir, 
																								 language.file.suffix, # e.g. 'chi' for chinese translation file
																								 module.file.prefix = 'recruitingappTranslation', # e.g. 'recruiting' or 'employee'
																								 workbook, 
																								 summary.sheet.name) {
	source('load_translation.R')
	source('constants.R')
	
	main1.file <- paste(file.dir, '/',module.file.prefix, '_', Translation$Xml.File.Suffix.Main1, '.xml', sep = '')
	main2.file <- paste(file.dir, '/',module.file.prefix, '_', Translation$Xml.File.Suffix.Main2, '.xml', sep = '')
	language.file <- paste(file.dir, '/',module.file.prefix, '_', language.file.suffix, '.xml', sep = '')
	

	###### initialisations, variables, constants, and function definitions ######
	
	# define cell style and color for Excel for highlighting
	## cell styles for translation sheets
	### define cell style and color for header row
	kCellStyleHeader <- createCellStyle(workbook)
	setFillPattern(kCellStyleHeader, fill = XLC$FILL.SOLID_FOREGROUND)
	setFillForegroundColor(kCellStyleHeader, color = XLC$COLOR.LIGHT_BLUE)

	### cell style for row ERROR
	kCellStyleSummaryError <- createCellStyle(workbook)
	setFillPattern(kCellStyleSummaryError, fill = XLC$FILL.SOLID_FOREGROUND)
	setFillForegroundColor(kCellStyleSummaryError, color = XLC$COLOR.RED)

	LanguageSummarySheetHandler <- function(summary.sheet.name) {
		kColumnNameDescription <- 'Description'
		kColumnNameOutput <- 'Output'
		kColumnLength <- 2
		start.row <- 1
		# the summary to be filled into the sheet
		summary.df <- data.frame(
			Description = character(),
			Output = character(),
			stringsAsFactors = FALSE
		)
		summary.df[start.row, kColumnNameDescription] <- paste(Translation$Xml.File.Suffix.Main1, 'file:')
		summary.df[start.row, kColumnNameOutput] <- main1.file
		start.row <- start.row + 1
		summary.df[start.row, kColumnNameDescription] <- paste(Translation$Xml.File.Suffix.Main2, 'file:')
		summary.df[start.row, kColumnNameOutput] <- main2.file
		start.row <- start.row + 1
		summary.df[start.row, kColumnNameDescription] <- paste(language.file.suffix, 'file:')
		summary.df[start.row, kColumnNameOutput] <- language.file
		start.row <- start.row + 1
		
		# return function to be used in LoadTranslation function
		function(result, mainDf, englishDf, languageDf) {
			summary.df[start.row, kColumnNameDescription] <- 
				paste('Number of translations in', Translation$Xml.File.Suffix.Main1, 'file:')
			summary.df[start.row, kColumnNameOutput] <- 
				nrow(mainDf)
			start.row <- start.row + 1
			
			summary.df[start.row, kColumnNameDescription] <- 
				paste('Number of translations in', Translation$Xml.File.Suffix.Main2, 'file:')
			summary.df[start.row, kColumnNameOutput] <- 
				nrow(englishDf)
			start.row <- start.row + 1
			
			summary.df[start.row, kColumnNameDescription] <- 
				paste('Number of translations in', language.file.suffix, 'file:')
			summary.df[start.row, kColumnNameOutput] <- 
				nrow(languageDf)
			start.row <- start.row + 1
			
			# check whether there are missing IDs
			main.df.not.in.lang.df <- mainDf[!mainDf$ID %in% languageDf$ID,]
			main.df.not.in.english.df <- mainDf[!mainDf$ID %in% englishDf$ID,]
			lang.df.not.in.main.df <- languageDf[!languageDf$ID %in% mainDf$ID,]
			english.df.not.in.main.df <- englishDf[!englishDf$ID %in% mainDf$ID,]
			
			# output ids from Main, missing in English file and store row number for cell style
			main.to.english.row.number = nrow(main.df.not.in.english.df)
			main.to.english.row.error <- if (main.to.english.row.number > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(main.to.english.row.number,
								'NEW id(s) in', Translation$Xml.File.Suffix.Main1, 'file but not in', Translation$Xml.File.Suffix.Main2, 'file:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(main.df.not.in.english.df$ID)
				start.row <- 
					start.row + 1
				start.row
			} else {
				-1
			}
			# output ids from Main, missing in language file and store row number for cell style
			main.to.lang.row.number = nrow(main.df.not.in.lang.df)
			main.to.lang.row.error <- if (main.to.lang.row.number > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(main.to.lang.row.number,
								'NEW id(s) in', Translation$Xml.File.Suffix.Main1, 'file but not in', language.file.suffix, 'file:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(main.df.not.in.lang.df$ID)
				start.row <- 
					start.row + 1
				start.row
			} else {
				-1
			}
			# output ids from English, missing in Main file and store row number for cell style
			english.to.main.row.number = nrow(english.df.not.in.main.df)
			english.to.main.row.error <- if (english.to.main.row.number > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(english.to.main.row.number,
								'OLD id(s) in', Translation$Xml.File.Suffix.Main2, 'file but not in', Translation$Xml.File.Suffix.Main1, 'file:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(english.df.not.in.main.df$ID)
				start.row <- 
					start.row + 1
				start.row
			} else {
				-1
			}
			# output ids from language, missing in Main file and store row number for cell style
			lang.to.main.row.number = nrow(lang.df.not.in.main.df)
			lang.to.main.row.error <- if (lang.to.main.row.number > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(lang.to.main.row.number,
								'OLD id(s) in', language.file.suffix, 'file but not in', Translation$Xml.File.Suffix.Main1, 'file:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(lang.df.not.in.main.df$ID)
				start.row <- 
					start.row + 1
				start.row
			} else {
				-1
			}
			# check in main1 text column for escape errors
			# like for '<' it should be '&lt;' and not '&lt;lt;'
			escape.row.error.list <- list()
			original.text.escape.list <- list()
			for (i in 1:nrow(result)) {
				resultRow <- result[i,]
				if (!is.na(cpos(resultRow[Translation$Xml.File.Suffix.Main1], 'amp;amp;')) 
						|| !is.na(cpos(resultRow[Translation$Xml.File.Suffix.Main1], 'lt;lt;'))
						|| !is.na(cpos(resultRow[Translation$Xml.File.Suffix.Main1], 'gt;gt;'))
						|| !is.na(cpos(resultRow[Translation$Xml.File.Suffix.Main1], 'apos;apos;'))
						|| !is.na(cpos(resultRow[Translation$Xml.File.Suffix.Main1], 'quot;quot;'))) {
					original.text.escape.list <- 
						c(original.text.escape.list, resultRow$ID)
				}
			}
			if (length(original.text.escape.list) > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(length(original.text.escape.list),
								'escape errors in attribute', 
								Translation$Xml.File.Suffix.Main1, 
								'with IDs:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(original.text.escape.list)
				start.row <- 
					start.row + 1
				escape.row.error.list <- c(escape.row.error.list, start.row)
			}
			# check in column 'Text' for escape errors
			# like for '<' it should be '&lt;' and not '&lt;lt;'
			text.escape.list <- list()
			for (i in 1:nrow(result)) {
				resultRow <- result[i,]
				if (!is.na(cpos(resultRow[language.file.suffix], 'amp;amp;')) 
						|| !is.na(cpos(resultRow[language.file.suffix], 'lt;lt;'))
						|| !is.na(cpos(resultRow[language.file.suffix], 'gt;gt;'))
						|| !is.na(cpos(resultRow[language.file.suffix], 'apos;apos;'))
						|| !is.na(cpos(resultRow[language.file.suffix], 'quot;quot;'))) {
					text.escape.list <- c(text.escape.list, resultRow$ID)
				}
			}
			if (length(text.escape.list) > 0) {
				summary.df[start.row, kColumnNameDescription] <- 
					paste(length(text.escape.list),
								'escape errors in attribute', 
								language.file.suffix,
								'with IDs:')
				summary.df[start.row, kColumnNameOutput] <- 
					toString(text.escape.list)
				start.row <- start.row + 1
				escape.row.error.list <- c(escape.row.error.list, start.row)
			}
			
			# create sheet only when it does not exists yet
			if (!summary.sheet.name %in% getSheets(workbook)) {
				createSheet(workbook, name = summary.sheet.name)
			}
			writeWorksheet(workbook, summary.df, sheet = summary.sheet.name)
			# output column description width is 100 characters long
			setColumnWidth(workbook, 
										 sheet = summary.sheet.name, 
										 column = which(colnames(summary.df) ==
										 							 	kColumnNameOutput), 
										 width = 100 * 256)
			# auto-size for description column
			setColumnWidth(workbook, 
										 sheet = summary.sheet.name, 
										 column = which(colnames(summary.df) == 
										 							 	kColumnNameDescription), 
										 width = 30 * 256)
			
			# cell styles for the sheet
			# header
			setCellStyle(workbook,
									 sheet = summary.sheet.name,
									 row = 1,
									 col = 1:kColumnLength,
									 cellstyle = kCellStyleHeader)
			# missing IDs in English file
			if (main.to.english.row.error != -1) {
				setCellStyle(workbook,
										 sheet = summary.sheet.name,
										 row = main.to.english.row.error,
										 col = 1:kColumnLength,
										 cellstyle = kCellStyleSummaryError)
			}
			# missing IDs in Language file
			if (main.to.lang.row.error != -1) {
				setCellStyle(workbook,
										 sheet = summary.sheet.name,
										 row = main.to.lang.row.error,
										 col = 1:kColumnLength,
										 cellstyle = kCellStyleSummaryError)
			}
			# missing IDs in Main file
			if (english.to.main.row.error != -1) {
				setCellStyle(workbook,
										 sheet = summary.sheet.name,
										 row = english.to.main.row.error,
										 col = 1:kColumnLength,
										 cellstyle = kCellStyleSummaryError)
			}
			# missing IDs in Main file
			if (lang.to.main.row.error != -1) {
				setCellStyle(workbook,
										 sheet = summary.sheet.name,
										 row = lang.to.main.row.error,
										 col = 1:kColumnLength,
										 cellstyle = kCellStyleSummaryError)
			}
			if (length(escape.row.error.list) > 0) {
				for (row.error in escape.row.error.list) {
					setCellStyle(workbook,
											 sheet = summary.sheet.name,
											 row = row.error,
											 col = 1:kColumnLength,
											 cellstyle = kCellStyleSummaryError)
				}
			}
		}
	}
	# load and return data frame
	LoadTranslation(main1.file, 
									main2.file, 
									language.file,
									language.file.suffix,
									LanguageSummarySheetHandler(summary.sheet.name))
}
