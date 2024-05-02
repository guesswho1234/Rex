var rnwTemplate = `<<echo=FALSE, results=hide>>=
@
%% \\exextra[editable,numeric]{1}
<<echo=FALSE, results=tex>>=
rnwTemplate_question=?rnwTemplate_question;
rnwTemplate_choices=?rnwTemplate_choices;
rnwTemplate_solutions=?rnwTemplate_solutions;
rnwTemplate_solutionNotes=?rnwTemplate_solutionNotes;
rnwTemplate_showFigure=TRUE;
rnwTemplate_figure=?rnwTemplate_figure;
rnwTemplate_maxChoices=5;
if(!is.null(rnwTemplate_maxChoices)){
	limit=min(length(rnwTemplate_choices), rnwTemplate_maxChoices)
	sel=sample(1:length(rnwTemplate_choices), limit)
	rnwTemplate_choices=rnwTemplate_choices[sel]
	rnwTemplate_solutions=rnwTemplate_solutions[sel]
	rnwTemplate_solutionNotes=rnwTemplate_solutionNotes[sel]
}
@
\\begin{question}
<<echo=FALSE, results=tex>>=
cat(rnwTemplate_question)
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
exams::answerlist(ifelse(rnwTemplate_solutions, "1", "0"), rnwTemplate_solutionNotes)
@
\\end{solution}
%% META-INFORMATION
%% \\extype{?rnwTemplate_type}
%% \\exsolution{\\Sexpr{exams::mchoice2string(rnwTemplate_solutions)}}
%% \\expoints{?rnwTemplate_points}
%% \\exsection{?rnwTemplate_section}
%% \\extags{?rnwTemplate_tags}`
