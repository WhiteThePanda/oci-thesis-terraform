#!/bin/bash
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
# Check version
fn version
# Start server
sudo fn start -d
# Set context
fn use context default
# Update registry
fn update context registry localdev
# Create python boiler plate
fn init --runtime python "blankfn"
# Copy the function we want to use
cp ~/functions/blankfn.py ~/blankfn/func.py
# Create app
fn create app blankapp
# Move to folder
cd blankfn
# Deploy locally
fn --verbose deploy --app blankapp --local