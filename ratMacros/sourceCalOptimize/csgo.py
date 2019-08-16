#!/usr/bin/env python3

import numpy as np

def bodyMacro(**kwargs):
    wallThickness  = kwargs.get("wallThickness", 5.0)
    scintThickness = kwargs.get("scintThickness", 2.0)
    scintHeight    = kwargs.get("scintHeight", 50.0)
    canRadius      = kwargs.get("canRadius", 55.0)
    canHeight      = kwargs.get("canHeight", 155.0)
    ## Build from scratch the source parameters
    airHeight = canHeight - wallThickness
    airRadius = canRadius - wallThickness
    ## scint all the way to the bottom
    scintPosZ = -(airHeight - scintHeight)
    ## Gas
    gasHeight = scintHeight - scintThickness
    gasRadius = airRadius - scintThickness
    ## PMT against the scintillator
    pmtPos    = -(airHeight - scintHeight*2)
    # Save to a set of files
    fileDescriptor = f"calopt_{wallThickness}_{scintThickness}_{scintHeight}_{canRadius}_{canHeight}"
    macName = fileDescriptor + '.mac'
    rootName = fileDescriptor + '.root'
    # Macro body
    body=\
    f'''
/control/execute header.mac
/rat/db/set GEO[sourcecan] r_max {canRadius}
/rat/db/set GEO[sourcecan] size_z {canHeight}
/rat/db/set GEO[sourceair] r_max {airRadius}
/rat/db/set GEO[sourceair] size_z {airHeight}
/rat/db/set GEO[sourcescint] size_z {scintHeight}
/rat/db/set GEO[sourcescint] r_max {airRadius}
/rat/db/set GEO[sourcescint] posz {scintPosZ}
/rat/db/set GEO[sourcegas] r_max {gasRadius}
/rat/db/set GEO[sourcegas] size_z {gasHeight}
/rat/db/set GEO[sourcepmt] posz {pmtPos}
/rat/proc outroot
/rat/procset file "{rootName}"
/control/execute footer.mac
    '''
    with open(macName, 'w') as f:
        f.write(body)

if __name__ == '__main__':
    # Case study 1: How thick is the scintillator
    #bodyMacro(
    #        canRadius=45.0,
    #        canHeight=130.0,
    #        scintHeight=20.0
    #        )
    # Case study 2: How tall of a volume do we need -- driven by flow so hard
    # Case study 3: Scintillator fixed, how thick is the steel (contain electron)
    thick = np.arange(19.0,20.0,1.0)
    for thickness in thick:
        bodyMacro( scintThickness = thickness )
