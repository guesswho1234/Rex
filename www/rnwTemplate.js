var rnwTemplate = `<<echo=FALSE, results=hide>>=
@
%% \\exextra[editable,numeric]{1}
<<echo=FALSE, results=tex>>=
question=?q
choices=?c
solutions=?s
maxChoices = 5
if(!is.null(maxChoices)){
	limit=min(length(choices), maxChoices)
	sel=sample(1:length(choices), limit)
	choices=choices[sel]
	solutions=solutions[sel]
}
@
\\begin{question}
\\Sexpr{question}
<<echo=FALSE, results=tex>>=
exams::answerlist(choices)
@
\\end{question}
\\begin{solution}
<<echo=FALSE, results=tex>>=
exams::answerlist(ifelse(solutions, "Richtig", "Falsch"))
@
\\end{solution}
%% META-INFORMATION
%% \\extype{mchoice}
%% \\exsolution{\\Sexpr{exams::mchoice2string(solutions)}}`
