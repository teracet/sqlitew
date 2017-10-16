# NSIS

This directory contains patched windows installer files.

In many other places in the repo, patching happens by running the original code through a script. However, in this case, the modifications were too complicated.

The main changes include updating branding info, removing file associations, and patching the generated shortcuts (which was done because using a launcher script in front of a binary on Windows is a little tricky). All of these changes can be found in the git history.
