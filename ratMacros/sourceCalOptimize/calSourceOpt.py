#!/usr/bin/env python
# coding: utf-8

import matplotlib.pyplot as plt
import numpy as np
from ROOT import TFile, AddressOf
import rat
import argparse

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--files', type=str, num='+')
    return parser.parse_args()

def parseMacro(macro):
    # Take the macro string and get the detector parameters
    msplit = macro.split('\n')
    print(msplit)
    
class FileParameters:
    def __init__(self, fname):
        fp = fname.replace('.root','')
        fp = fp.split('_')
        _, self.wallThickness, self.scintThickness, self.scintHeight, self.canRadius, self.canHeight = fp
        
def analyze(fname):
    tfile = TFile(fname)
    #params = FileParameters(fname)
    
    runT = tfile.Get("runT")
    run = rat.RAT.DS.Run()
    runT.SetBranchAddress("run", AddressOf(run))
    runT.GetEntry(0)
    pmtinfo = run.GetPMTInfo()
    
    tree = tfile.Get("T")
    ds = rat.RAT.DS.Root()
    tree.SetBranchAddress("ds", AddressOf(ds))
    
    print(tree.GetEntries())
    gamma_primaries = {}
    gamma_deposits = {}
    gamma_volumes = set()
    pe = []
    cherenkov = []

    for ent in range(tree.GetEntries()):
        tree.GetEntry(ent)
        mc = ds.GetMC()
        pe.append(mc.GetNumPE())
        ntracks = mc.GetMCTrackCount()
        npmt = mc.GetMCPMTCount()
        nScint = mc.GetMCSummary().GetNumScintPhoton()
        #print(f'Event: {ent} with {ntracks} tracks and {nScint} photons')
        cherenkov.append(mc.GetMCSummary().GetNumCerenkovPhoton())
        for track_id in range(ntracks):
            track = mc.GetMCTrack(track_id)
            parent = track.GetParentID()
            if parent != 0:
                continue
            name = track.GetParticleName()
            if name == "opticalphoton":
                continue
            ## Track gammas
            #if name == "e-":
            #    continue
            #if name == "e+":
            #    continue
            nsteps = track.GetMCTrackStepCount()
            #print(f'Mom? {track.GetParentID()}, I am {track.GetID()}')
            for step_id in range(nsteps):
                step = track.GetMCTrackStep(step_id)
                if step_id == 0:
                    start_energy = step.GetKE()
                    start_volume = step.GetVolume()
                    gamma_volumes.add(start_volume)
                    energy = start_energy
                    #print(f'    Name: {name} -- {energy} ID: {track.GetID()} {track_id} {parent} -- {track.GetLength()} {nsteps}')
                else:
                    volume = step.GetVolume()
                    if volume == "detector":
                        try:
                            gamma_deposits[start_energy].append(energy)
                        except KeyError:
                            gamma_deposits[start_energy] = [energy]
                        break
                    energy = step.GetKE()
                
        # Loop over the one pmt to get charge, check its type==3
        for ipmt in range(npmt):
            pmt = mc.GetMCPMT(ipmt)
            pmtid = pmt.GetID()
            #print(f'pmtid: {pmtid}')
        # Loop over the gamma tracks, maybe we turn off optical photons
        #print(f'npmt: {npmt}')
    return gamma_deposits, gamma_volumes, pe, cherenkov    
    
output, volumes, pe, cherenkov = analyze('1mm.root')

np.savez('output', gamma=output, volumes=volumes, pe=pe, cherenkov=cherenkov)
