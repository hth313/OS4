import sys
sys.path.insert(0, '../module/lcd41')

import os
import subprocess
from lcd import *

lcd = LCD41()
prgmMode = Anns()
prgmMode.annPRGM.set()

images = [ ("lcd-less-than-program-1", lcd.image("05 &lt; __", prgmMode))
         , ("lcd-less-than-program-2", lcd.image("05 &lt; ST _", prgmMode))
         , ("lcd-less-than-program-3", lcd.image("05 &lt; Z __", prgmMode))
         , ("lcd-less-than-program-4", lcd.image("5 &lt; Z IND __", prgmMode))
         , ("lcd-less-than-program-5", lcd.image("05`ÿÿ", prgmMode))
         , ("lcd-less-than-program-6", lcd.image("Z &lt; IND 10?", prgmMode))
         , ("lcd-less-than-program-7", lcd.image("06 M &lt;= L?", prgmMode))
         ]

for (file, body) in images:
    svgfile = file + ".svg"
    pdffile = file + ".pdf"
    f = open(os.path.join("_static", svgfile), "w")
    f.write(body)
    f.close()
    command_line = ["inkscape", "--export-filename=" + pdffile, "--export-dpi=96", svgfile]
    subprocess.call(command_line, cwd="_static")
