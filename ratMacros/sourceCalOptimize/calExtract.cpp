// Rewrite in Julia
#include <TFile.h>
#include <TTree.h>
#include <RAT/DS/Root.hh>
#include <RAT/DS/MC.hh>
#include <RAT/DS/MCTrack.hh>
#include <RAT/DS/MCTrackStep.hh>
#include <string>
#include <iostream>
#include <map>
#include <vector>
#include <set>
#include <stdio.h>
using namespace RAT::DS;
using namespace std;
string newname(string);

int main(int argc, char** argv)
{
  TFile* tfile = new TFile(argv[1]);
  TTree* tree = (TTree*)tfile->Get("T");

  Root* ds = new Root();
  tree->SetBranchAddress("ds", &ds);

  map<double, vector<double>> gamma_deposits;
  set<string> gamma_volumes;
  vector<double> pe;
  vector<double> cherenkov;

  size_t ent = tree->GetEntries();
  for(int i=0; i<ent; i++)
  {
    tree->GetEntry(i);
    MC* mc = ds->GetMC();
    pe.push_back(mc->GetNumPE());
    size_t ntracks = mc->GetMCTrackCount();
    size_t npmt = mc->GetMCPMTCount();
    int nScint = mc->GetMCSummary()->GetNumScintPhoton();
    cherenkov.push_back(mc->GetMCSummary()->GetNumCerenkovPhoton());
    for( int track_id=0; track_id<ntracks; track_id++ )
    {
      MCTrack* track = mc->GetMCTrack(track_id);
      int parent = track->GetParentID();
      if( parent != 0 ) continue;
      string name = track->GetParticleName();
      if( name == "opticalphoton" ) continue;
      size_t nsteps = track->GetMCTrackStepCount();
      double start_energy = 0, energy=0;
      string start_volume;
      for( int step_id=0; step_id < nsteps; step_id++ )
      {
        MCTrackStep* step = track->GetMCTrackStep(step_id);
        if( step_id == 0 )
        {
          start_energy = step->GetKE();
          start_volume = step->GetVolume();
          gamma_volumes.insert(start_volume);
          energy = start_energy;
        }
        else
        {
          string volume = step->GetVolume();
          if( volume == "detector" )
            gamma_deposits[start_energy].push_back(energy);
          break;
          energy = step->GetKE();
        }
      }
    }
    if(i%10==0)
      fprintf(stderr, "Proc: %2.2f \%\r", double(i)/ent*100);
  }
  string oName = newname(argv[1]);
  TFile* outfile = new TFile(oName.c_str(), "recreate");
  TTree* gtree = new TTree("gamma", "gamma");
  vector<double> v;
  double gammaE;
  gtree->Branch("energy", &gammaE);
  gtree->Branch("vector", &v);
  for(auto const& x : gamma_deposits)
  {
    gammaE = x.first;
    v = x.second;
    gtree->Fill();
  }
  TTree* petree = new TTree("pe", "pe");
  double ape;
  petree->Branch("pe", &ape);
  for(auto& x : pe)
  {
    ape = x;
    petree->Fill();
  }
  //TTree* outT = new TTree("data", "data");

  outfile->Write();
  return 0;
}

string newname(string oldname)
{
  std::size_t pos = oldname.find(".root");
  return oldname.replace(pos, 5, "_data.root");
}
