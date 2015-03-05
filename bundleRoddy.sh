rm -rf Roddy
mkdir Roddy
cp ~/Roddy/roddy.sh Roddy
cp ~/Roddy/*.ini Roddy
cp -r ~/Roddy/helperScripts Roddy
cp -r ~/Roddy/dist Roddy
cp -r ~/RoddyWorkflows/Plugins/COWorkflows_1.0.104* Roddy/dist/plugins
cp ~/RoddyWorkflows/COProjectConfigurations/co* Roddy/dist/resources/configurationFiles
cp ~/RoddyWorkflows/COProjectConfigurations/PBS* Roddy/dist/resources/configurationFiles
cp ~/RoddyWorkflows/COProjectConfigurations/projectsPanCancer.xml Roddy/dist/resources/configurationFiles


