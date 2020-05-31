# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# http://www.sphinx-doc.org/en/master/config

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
import shlex
import cloud_sptheme as csp
sys.path.insert(0, os.path.abspath('.'))


# -- Project information -----------------------------------------------------

project = 'OS4'
copyright = '2020, Håkan Thörngren'
author = 'Håkan Thörngren'

# The full version, including alpha/beta/rc tags
release = '1B'

# The master toctree document.
master_doc = 'index'

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'cloud_sptheme.ext.table_styling'
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'cloud'

# Add any paths that contain custom themes here, relative to this directory.
html_theme_path = [csp.get_theme_dir()]

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# -- Options for LaTeX output ---------------------------------------------

latex_engine = 'xelatex'

latex_show_urls = 'footnote'

latex_elements = {
# The paper size ('letterpaper' or 'a4paper').
#'papersize': 'letterpaper',

# The font size ('10pt', '11pt' or '12pt').
#'pointsize': '10pt',

    'fncychap': '\\usepackage[Sonny]{fncychap}',

    # Additional stuff for the LaTeX preamble.
    'preamble': r'''
\usepackage{fontspec}
% This gives lowered numbers, but I am not sure I like that, so it is disabled
% \usepackage[osf,sups,scaled=.97]{XCharter} % osf for text, not math
\usepackage{XCharter}
% \usepackage{cabin} % sans serif
% More distunguised lower-case L, no slash through 0
\usepackage[varqu,varl,var0]{inconsolata} % sans serif typewriter
\usepackage[libertine,bigdelims,vvarbb,scaled=1.03]{newtxmath} % bb from STIX
\usepackage[cal=boondoxo]{mathalfa} % mathcal
\usepackage[utf8]{inputenc}
\usepackage{amssymb}
\usepackage{newunicodechar}
\newunicodechar{Σ}{$\Sigma$}
\newunicodechar{μ}{$\mu$}
\newunicodechar{÷}{$\div$}
\newunicodechar{≤}{$\leq$}
\newunicodechar{≠}{$\neq$}
\newunicodechar{⊀}{$\measuredangle$}
\newunicodechar{├}{$\vdash$}
''',

    # disable font inclusion
    'fontpkg': '',
    'fontenc': '',

    # Fix Unicode handling by disabling the defaults for a few items
    # set by sphinx
    'inputenc': '',
    'utf8extra': '',

    # fix missing index entry due to RTD doing only once pdflatex after makeindex
    'printindex': r'''
\IfFileExists{\jobname.ind}
             {\footnotesize\raggedright\printindex}
             {\begin{sphinxtheindex}\end{sphinxtheindex}}
''',

}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
  (master_doc, 'OS4.tex', u'OS4 Documentation',
   u'Håkan Thörngren', 'manual'),
]

# The name of an image file (relative to this directory) to place at the top of
# the title page.
latex_logo = '_static/coverGreenNoBackground.jpg'

# For "manual" documents, if this is true, then toplevel headings are parts,
# not chapters.
#latex_use_parts = False

# If true, show page references after internal links.
#latex_show_pagerefs = False

# If true, show URL addresses after external links.
#latex_show_urls = False

# Documents to append as an appendix to all manuals.
#latex_appendices = []

# If false, no module index is generated.
#latex_domain_indices = True

# -- Options for Epub output ----------------------------------------------

# Bibliographic Dublin Core info.
epub_title = u'OS4'
epub_author = u'Håkan Thörngren'
epub_publisher = u'hth313@gmail.com'
epub_copyright = u'2020, Håkan Thörngren'

# The basename for the epub file. It defaults to the project name.
#epub_basename = u'Lib41'

# The HTML theme for the epub output. Since the default themes are not optimized
# for small screen space, using the same theme for HTML and epub output is
# usually not wise. This defaults to 'epub', a theme designed to save visual
# space.
#epub_theme = 'epub'

# The language of the text. It defaults to the language option
# or en if the language is not set.
#epub_language = ''

# The scheme of the identifier. Typical schemes are ISBN or URL.
#epub_scheme = ''

# The unique identifier of the text. This can be a ISBN number
# or the project homepage.
#epub_identifier = ''

# A unique identification for the text.
#epub_uid = ''

# A tuple containing the cover image and cover page html template filenames.
epub_cover = ('_static/coverGreen.jpg', '')

# A sequence of (type, uri, title) tuples for the guide element of content.opf.
#epub_guide = ()

# HTML files that should be inserted before the pages created by sphinx.
# The format is a list of tuples containing the path and title.
#epub_pre_files = []

# HTML files shat should be inserted after the pages created by sphinx.
# The format is a list of tuples containing the path and title.
#epub_post_files = []

# A list of files that should not be packed into the epub file.
#epub_exclude_files = []

# The depth of the table of contents in toc.ncx.
#epub_tocdepth = 3

# Allow duplicate toc entries.
#epub_tocdup = True

# Choose between 'default' and 'includehidden'.
#epub_tocscope = 'default'

# Fix unsupported image types using the PIL.
#epub_fix_images = False

# Scale large images.
#epub_max_image_width = 0

# How to display URL addresses: 'footnote', 'no', or 'inline'.
#epub_show_urls = 'inline'

# If false, no index is generated.
#epub_use_index = True
