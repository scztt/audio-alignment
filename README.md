# Experiments with audio alignment / gunshot detection using SuperCollider.

This is an initial experiment at building flexible offline audio processing pipelines for machine listening and analysis. The specific goal is to align audio segments with the same semantic content but different recording qualities and/or time offets.

The pipeline currently consumes a single audio file, specified in Settings.scd. It produces several copies of it with broadband noise added, and then attempts to match small temporal fragmemnts of these with the other fuzzed copies. The aligned results are then displayed. Fuzzed variations are specified with the ~noiseLevels and ~noiseSettings parameters in Settings.scd. Test cases consisting of [input_file_index, start_time, end_time] (where input_file_index refers to an index in ~noiseSettings) are specified in TestCases.scd.

# Setup
1. Install a new version of SuperCollider and the SC3-Plugins extensions, available here:

https://supercollider.github.io/download

https://supercollider.github.io/sc3-plugins/

2. Run the code in Setup.scd once. *(Running code can be accomplished by selecting it / Cmd+A and using Cmd+Return in SuperCollider)*

3. Language menu -> Recompile Class Library

4. Specify a correct file path in Settings.scd. The example audio file used for testing is available here:
https://drive.google.com/file/d/1jOvr-vg4lpFmg5zBLFuMES46yvhuW5Am/view?usp=sharing

5. Run all code in Detection.scd (processing and analysis should take 1-2 minutes)
