var rnwTemplate = `<<echo=FALSE, results=hide>>=
@
%% \\exextra[editable,numeric]{1}
%% \\exextra[examHistory,character]{}
%% \\exextra[authoredBy,character]{}
%% \\exextra[topic,character]{?rnwTemplate_t}
%% \\exextra[tags,character]{}
<<echo=FALSE, results=tex>>=
rnwTemplate_question=?rnwTemplate_q
rnwTemplate_choices=?rnwTemplate_c
rnwTemplate_solutions=?rnwTemplate_s
rnwTemplate_points=?rnwTemplate_p
rnwTemplate_figure=?rnwTemplate_f
rnwTemplate_maxChoices = 5
if(!is.null(rnwTemplate_maxChoices)){
	limit=min(length(rnwTemplate_choices), rnwTemplate_maxChoices)
	sel=sample(1:length(rnwTemplate_choices), limit)
	rnwTemplate_choices=rnwTemplate_choices[sel]
	rnwTemplate_solutions=rnwTemplate_solutions[sel]
}
rnwTemplate_showFigure = TRUE
@
\\begin{question}
\\Sexpr{rnwTemplate_question}
<<echo=FALSE, results=tex>>=
if(rnwTemplate_showFigure && length(rnwTemplate_figure) == 3) {
	rnwTemplate_figureFile = paste0(rnwTemplate_figure[1], ".", rnwTemplate_figure[2])
	rnwTemplate_figureRaw = openssl::base64_decode(rnwTemplate_figure[3])
	writeBin(rnwTemplate_figureRaw, con = rnwTemplate_figureFile)
	cat("\\\\\\\\")
	cat(paste0("\\\\includegraphics\{", rnwTemplate_figureFile, "\}"))
} 
@
%
<<echo=FALSE, results=tex>>=
exams::answerlist(rnwTemplate_choices)
@
\\end{question}

\\begin{solution}
<<echo=FALSE, results=tex>>=
exams::answerlist(ifelse(rnwTemplate_solutions, "Richtig", "Falsch"))
@
\\end{solution}
%% META-INFORMATION
%% \\extype{mchoice}
%% \\exsolution{\\Sexpr{exams::mchoice2string(rnwTemplate_solutions)}}
%% \\expoints{\\Sexpr{rnwTemplate_points}}`
