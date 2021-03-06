# Copyright (c) 2020, Adrian Dusa
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, in whole or in part, are permitted provided that the
# following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The names of its contributors may NOT be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL ADRIAN DUSA BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

`venn` <-
function(x, snames = "", counts = NULL, ilabels = FALSE, ellipse = FALSE,
     zcolor = "bw", opacity = 0.3, plotsize = 15, ilcs = 0.6, sncs = 0.85,
     borders = TRUE, box = TRUE, par = TRUE, ggplot = FALSE, ...) {
    if (missing(x)) {
        cat("\n")
        stop(simpleError("Argument \"x\" is missing.\n\n"))
    }
    if (ggplot) {
        ilcs <- 2.5
        sncs <- 3.5
        if (!requireNamespace("ggplot2", quietly = TRUE) | !requireNamespace("ggpolypath", quietly = TRUE)) {
            cat("\n")
            stop("Packages \"ggplot2\" and \"ggpolypath\" are needed to make this work, please install.", call. = FALSE)
        }
    }
    funargs <- unlist(lapply(match.call(), deparse)[-1])
    if (!is.element("cexil", names(funargs))) {
        names(funargs)[which(names(funargs) == "cexil")] <- "ilcs"
    }
    if (!is.element("cexsn", names(funargs))) {
        names(funargs)[which(names(funargs) == "cexsn")] <- "sncs"
    }
    if (inherits(tryCatch(eval(x), error = function(e) e), "error")) {
        x <- funargs["x"]
    }
    if (is.numeric(x)) {
        if (length(x) > 1) {
            cat("\n")
            stop(simpleError("Argument \"x\" can be a single digit, for up to 7 sets.\n\n"))
        }
    }
    if (!identical(zcolor, "bw") & !identical(zcolor, "style")) {
        zcolor <- unlist(strsplit(gsub("[[:space:]]", "", zcolor), split = ","))
        testcolor <- tryCatch(col2rgb(zcolor), error = function(e) e)
        if (!is.matrix(testcolor)) {
            cat("\n")
            stop(simpleError("Invalid color(s) in \"zcolor\".\n\n"))
        }
    }
    nofsets <- 0
    if (!identical(snames, "")) {
        if (!is.character(snames)) {
            cat("\n")
            stop(simpleError("The \"snames\" argument should be character.\n\n"))
        }
        if (length(snames) == 1) snames <- admisc::splitstr(snames)
        nofsets <- length(snames)
    }
    ttqca <- FALSE
    listx <- FALSE
    cts <- NULL
    if (is.numeric(counts) & is.numeric(x)) {
        if (length(counts) == 2^x) {
            cts <- counts
            counts <- TRUE
        }
        else {
            counts <- FALSE
        }
    }
    else {
        counts <- FALSE
    }
    if (any(is.element(c("qca", "QCA_min", "tt", "QCA_tt"), class(x)))) {
        ttqca <- TRUE
        otype <- "input"
        if (any(is.element(c("tt", "QCA_tt"), class(x)))) {
            QCA <- all(which(is.element(c("minmat", "DCC", "options", "neg.out", "opts"), names(x))) < 4)
            otype <- "truth table"
            tt <- x$tt
            snames <- unlist(strsplit(gsub("[[:space:]]", "", x$options$conditions), split = ","))
            noflevels <- x$noflevels
        }
        else {
            QCA <- all(which(is.element(c("minmat", "DCC", "options", "neg.out", "opts"), names(x$tt))) < 4)
            otype <- "minimization"
            oq <- TRUE
            tt <- x$tt$tt
            snames <- unlist(strsplit(gsub("[[:space:]]", "", x$tt$options$conditions), split = ","))
            noflevels <- x$tt$noflevels
        }
        if (!QCA) {
            cat("\n")
            stop(simpleError(sprintf("Please create a proper %s object with package QCA.\n\n", otype)))
        }
        if (any(noflevels != 2)) {
            cat("\n")
            stop(simpleError("Venn diagrams are not possible for multivalue data.\n\n"))
        }
        if (nofsets == 0) {
            nofsets <- length(snames)
        }
        if (nofsets < 4 | nofsets > 5) {
            ellipse <- FALSE
        }
        ttcolors <- c(
            "0" = "#ffd885",
            "1" = "#96bc72",
            "C" = "#1c8ac9",
            "?" = "#ffffff" # white
        )
        if (identical(zcolor, "style")) {
            zcolor <- "bw"
        }
        else if (!identical(zcolor, "bw")) {
            if (is.character(zcolor) & length(zcolor) >= 3) {
                ttcolors[c("0", "1", "C")] <- zcolor[1:3]
            }
        }
        individual <- length(opacity) == nrow(tt)
        gvenn <- openPlot(plotsize, par = par, ggplot = ggplot)
        if (individual) {
            for (i in seq(nrow(tt))) {
                if (tt$OUT[i] != "?") {
                    color <- adjustcolor(ttcolors[tt$OUT[i]], alpha.f = as.numeric(opacity[i]))
                    if (i == 1) {
                        zeroset <- matrix(c(0, 1000, 1000, 0, 0, 0, 0, 1000, 1000, 0), ncol = 2)
                        colnames(zeroset) <- c("x", "y")
                        polygons <- rbind(zeroset, rep(NA, 2), getZones(0, nofsets, ellipse)[[1]])
                        polygons <- polygons[-nrow(polygons), ]
                        if (is.null(gvenn)) {
                            polypath(polygons, rule = "evenodd", col = color, border = NA)
                        }
                        else {
                            gvenn <- gvenn + ggpolypath::geom_polypath(polygons, rule = "evenodd", col = color)
                        }
                    }
                    else {
                        plotdata <- ints[ints$s == nofsets & ints$v == as.numeric(ellipse) & ints$i == i, c("x", "y")]
                        if (is.null(gvenn)) {
                            polygon(plotdata, col = color)
                        }
                        else {
                            gvenn <- gvenn + ggplot2::geom_polygon(data = plotdata, ggplot2::aes(x, y), fill = color)
                        }
                    }
                }
            }
        }
        else {
            for (i in names(ttcolors)[1:3]) {
                zones <- as.numeric(rownames(tt[tt$OUT == i, ]))
                if (length(zones) > 0) {
                    if (any(zones == 1)) {
                        zeroset <- matrix(c(0, 1000, 1000, 0, 0, 0, 0, 1000, 1000, 0), ncol = 2)
                        colnames(zeroset) <- c("x", "y")
                        polygons <- rbind(zeroset, rep(NA, 2), getZones(0, nofsets, ellipse)[[1]])
                        polygons <- polygons[-nrow(polygons), ]
                        if (is.null(gvenn)) {
                            polypath(polygons, rule = "evenodd", col = ttcolors[i], border = NA)
                        }
                        else {
                            gvenn <- gvenn + ggpolypath::geom_polypath(polygons, rule = "evenodd", col = ttcolors[i])
                        }
                        zones <- zones[-1]
                    }
                    plotdata <- ints[ints$s == nofsets & ints$v == as.numeric(ellipse) & is.element(ints$i, zones), c("x", "y")]
                    if (is.null(gvenn)) {
                        polygon(plotdata, col = ttcolors[i])
                    }
                    else {
                        gvenn <- gvenn + ggplot2::geom_polygon(data = plotdata, ggplot2::aes(x, y), fill = ttcolors[i])
                    }
                }
            }
        }
        cts <- tt$n
        x <- nofsets
    }
    else if (is.numeric(x)) {
        nofsets <- x
        if (!identical(snames, "")) {
            if (length(snames) != nofsets) {
                cat("\n")
                stop(simpleError("Number of sets not equal with the number of set names.\n\n"))
            }
        }
    }
    else if (is.character(x)) {
        if (any(grepl("\\$solution", funargs["x"]))) {
            obj <- get(unlist(strsplit(funargs["x"], split = "[$]"))[1])
            snames <- obj$tt$options$conditions
            nofsets <- length(snames)
        }
        x <- unlist(strsplit(gsub("[[:space:]]", "", x), split = ","))
        if (all(grepl("[A-Za-z]", x))) { 
            if (identical(snames, "")) {
                y <- admisc::translate(paste(x, collapse = "+"), snames = snames)
                snames <- colnames(y)
                nofsets <- length(snames)
            }
            x <- lapply(x, function(x) {
                return(paste(apply(admisc::translate(x, snames = snames), 1, function(x) {
                    x[x < 0] <- "-"
                    paste(x, collapse = "")
                }), collapse = "+"))
            })
        }
        if (!is.list(x)) {
            if (!all(gsub("0|1|-|\\+", "", x) == "")) {
                cat("\n")
                stop(simpleError("Invalid codes in the rule(s).\n\n"))
            }
            if (nofsets == 0) {
                nofsets <- unique(nchar(unlist(strsplit(x, split = "\\+"))))
            }
            x <- as.list(x)
        }
    }
    else if (is.data.frame(x)) {
        if (!is.null(names(x))) {
            if (all(names(x) != "")) {
                snames <- names(x)
            }
        }
        if (!all(is.element(unique(unlist(x)), c(0, 1)))) {
            cat("\n")
            stop(simpleError("As a dataframe, \"x\" can only contain values 0 and 1.\n\n"))
        }
        if (nofsets == 0) {
            nofsets <- length(x)
        }
        cts <- apply(sapply(rev(seq(nofsets)), function(x) {
            rep.int(c(sapply(0:1, function(y) rep.int(y, 2^(x - 1)))), 2^nofsets/2^x)}), 1,
            function(l1) {
                sum(apply(x, 1, function(l2) {
                    all(l1 == l2)
                }))
            }
        )
        counts <- TRUE
        x <- nofsets
    }
    else if (is.list(x)) {
        if (any(grepl("\\$solution", funargs["x"]))) {
            obj <- get(unlist(strsplit(funargs["x"], split = "[$]"))[1])
            snames <- obj$tt$options$conditions
            nofsets <- length(snames)
            x <- admisc::translate(paste(unlist(x), collapse = " + "), snames = snames)
            x <- as.list(apply(x, 1, function(y) {
                y[y < 0] <- "-"
                paste(y, collapse = "")
            }))
        }
        else {
            listx <- TRUE
            if (length(x) > 7) {
                x <- x[seq(7)]
            }
            if (!is.null(names(x))) {
                if (all(names(x) != "")) {
                    snames <- names(x)
                }
            }
            if (identical(snames, "")) {
                snames <- LETTERS[seq(length(x))]
            }
            if (nofsets == 0) {
                nofsets <- length(x)
            }
            tt <- sapply(rev(seq(nofsets)), function(x) {
                      rep.int(c(sapply(0:1, function(y) rep.int(y, 2^(x - 1)))), 2^nofsets/2^x)})
            colnames(tt) <- snames
            intersections <- apply(tt, 1,
                function(y) {
                    setdiff(Reduce(intersect, x[y == 1]), unlist(x[y == 0]))
                }
            )
            names(intersections) <- apply(tt, 1, function(x) paste(snames[x == 1], collapse = ":"))
            cts <- unlist(lapply(intersections, length))
            intersections <- intersections[cts > 0]
            tt <- as.data.frame(cbind(tt, counts = cts))
            attr(tt, "intersections") <- intersections
            counts <- TRUE
            x <- nofsets
        }
    }
    else {
        cat("\n")
        stop(simpleError("Unrecognised argument \"x\".\n\n"))
    }
    if (nofsets > 7) {
        cat("\n")
        stop(simpleError("Venn diagrams can be drawn up to 7 sets.\n\n"))
    }
    if (identical(snames, "")) {
        snames <- LETTERS[seq(nofsets)]
    }
    else {
        if (length(snames) != nofsets) {
            cat("\n")
            stop(simpleError("Length of set names does not match the number of sets.\n\n"))
        }
    }
    if (!is.element("ilcs", names(funargs))) {
        if (!ggplot) {
            ilcs <- ilcs - ifelse(nofsets > 5, 0.1, 0) - ifelse(nofsets > 6, 0.05, 0)
        }
    }
    if (!ttqca) {
        gvenn <- openPlot(plotsize, par = par, ggplot = ggplot)
    }
    gvenn <- plotRules(x, zcolor, ellipse, opacity, allborders = borders, 
                        box = box, gvenn = gvenn, ... = ...)
    scoords <- data.frame(
        s = c(1, rep(2, 2), rep(3, 3), rep(4, 4), rep(5, 10), rep(6, 6), rep(7, 7), rep(4, 4)),
        v = c(rep(0, 1 + 2 + 3), rep(1, 4), rep(0:1, each = 5), rep(0, 6 + 7), rep(0, 4)), 
        x = c(500, 250, 750, 100, 500, 900,  88, 263, 713, 888,     80, 535, 900, 700, 120,      88, 533, 850, 750, 163,       100, 500, 910, 925, 550, 100, 220, 685, 935, 935, 600, 155,  50,  85, 220, 780, 915),
        y = c(780, 780, 780, 560, 910, 560, 663, 850, 850, 663,    800, 960, 700,  50, 120,     750, 963, 688,  40,  88,       860, 975, 775, 165,  30, 140, 955, 980, 780, 200,  15, 120, 690, 670, 850, 850, 670)
    )
    if (ilabels | counts & !is.null(cts)) {
        ilabels <- icoords$l[icoords$s == nofsets & icoords$v == as.numeric(ellipse)]
        if (counts) {
            cts[cts == 0] <- ""
            ilabels <- cts
        }
        icoords <- icoords[icoords$s == nofsets & icoords$v == as.numeric(ellipse), c("x", "y")]
        if (ggplot) {
            for (i in seq(length(ilabels))) {
                gvenn <- gvenn + ggplot2::annotate("text", label = ilabels[i], x = icoords$x[i], y = icoords$y[i], size = ilcs)
            }
        }
        else {
            text(icoords, labels = ilabels, cex = ilcs)
        }
    }
    scoords <- scoords[scoords$s == nofsets & scoords$v == as.numeric(ellipse), c("x", "y")]
    if (ggplot) {
        for (i in seq(length(snames))) {
            gvenn <- gvenn + ggplot2::annotate("text", label = snames[i], x = scoords$x[i], y = scoords$y[i], size = sncs)
        }
    }
    else {
        text(scoords, labels = snames, cex = sncs)
    }
    if (ttqca) {
        if (is.null(gvenn)) {
            points(seq(10, 340, length.out = 4), rep(-25, 4), pch = 22, bg = ttcolors, cex = 1.75)
            text(seq(40, 370, length.out = 4), rep(-26, 4), names(ttcolors), cex = 0.85)
        }
        else {
            gvenn <- gvenn +
            ggplot2::annotate("rect", xmin = 10, xmax = 32, ymin = -44, ymax = -22, fill = ttcolors[1], col = "black") + 
            ggplot2::annotate("rect", xmin = 120, xmax = 142, ymin = -44, ymax = -22, fill = ttcolors[2], col = "black") + 
            ggplot2::annotate("rect", xmin = 230, xmax = 252, ymin = -44, ymax = -22, fill = ttcolors[3], col = "black") + 
            ggplot2::annotate("rect", xmin = 340, xmax = 362, ymin = -44, ymax = -22, fill = ttcolors[4], col = "black") +
            ggplot2::annotate("text", x = 50, y = -34, label = names(ttcolors)[1]) +
            ggplot2::annotate("text", x = 160, y = -34, label = names(ttcolors)[2]) +
            ggplot2::annotate("text", x = 270, y = -34, label = names(ttcolors)[3]) +
            ggplot2::annotate("text", x = 380, y = -34, label = names(ttcolors)[4])
        }
    }
    if (ggplot) {
        return(gvenn)
    }
    if (listx) {
        return(invisible(tt))
    }
}
