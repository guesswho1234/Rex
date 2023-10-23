var xmlToRnw = `<<echo=FALSE, results=tex>>=
question=?q
choices=?c
solutions=?s
limit=min(length(choices), 5)
sel=sample(1:length(choices), limit)
choices=choices[sel]
solutions=solutions[sel]
@
\\begin{question}
\\Sexpr{question}

<<echo=FALSE, results=tex>>=
answerlist(choices)
@
\\end{question}
\\begin{solution}
<<echo=FALSE, results=tex>>=
answerlist(ifelse(solutions, "Richtig", "Falsch"))
@
\\end{solution}
%% META-INFORMATION
%% \\extype{mchoice}
%% \\exsolution{\\Sexpr{mchoice2string(solutions)}}`
