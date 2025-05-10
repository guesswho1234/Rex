var rnwTemplate = `<<echo=FALSE, results=tex>>=
rxxTemplate_question=?rxxTemplate_question;
rxxTemplate_choices=?rxxTemplate_choices;
rxxTemplate_solutions=?rxxTemplate_solutions;
rxxTemplate_solutionNotes=?rxxTemplate_solutionNotes;
rxxTemplate_showFigure=TRUE;
rxxTemplate_figure=?rxxTemplate_figure;
rxxTemplate_maxChoices=5;
if(!is.null(rxxTemplate_maxChoices)){
	limit=min(length(rxxTemplate_choices), rxxTemplate_maxChoices)
	sel=sample(1:length(rxxTemplate_choices), limit)
	rxxTemplate_choices=rxxTemplate_choices[sel]
	rxxTemplate_solutions=rxxTemplate_solutions[sel]
	rxxTemplate_solutionNotes=rxxTemplate_solutionNotes[sel]
}
@
\\begin{question}
<<echo=FALSE, results=tex>>=
cat(rxxTemplate_question)
if(rxxTemplate_showFigure && length(rxxTemplate_figure) == 3) {
	rxxTemplate_figureFile = paste0(rxxTemplate_figure[1], ".", rxxTemplate_figure[2])
	rxxTemplate_figureRaw = openssl::base64_decode(rxxTemplate_figure[3])
	writeBin(rxxTemplate_figureRaw, con = rxxTemplate_figureFile)
	cat("\\\\\\\\")
	cat(paste0("\\\\includegraphics\{", rxxTemplate_figureFile, "\}"))
} 
@
%
<<echo=FALSE, results=tex>>=
exams::answerlist(rxxTemplate_choices)
@
\\end{question}

\\begin{solution}
<<echo=FALSE, results=tex>>=
exams::answerlist(ifelse(rxxTemplate_solutions, "1", "0"), rxxTemplate_solutionNotes)
@
\\end{solution}
%% META-INFORMATION
%% \\exextra[editable,numeric]{1}
%% \\extype{?rxxTemplate_type}
%% \\exsolution{\\Sexpr{exams::mchoice2string(rxxTemplate_solutions)}}
%% \\exauthor{?rxxTemplate_author}
%% \\expoints{?rxxTemplate_points}
%% \\exsection{?rxxTemplate_section}
%% \\extags{?rxxTemplate_tags}`
