# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

from mozbuild.base import MozbuildObject
from mozpack import dmg

import os
import sys


def make_dmg(source_directory, output_dmg):
    build = MozbuildObject.from_environment()
    extra_files = [
        (os.path.join(build.distdir, 'branding', 'dsstore'), '.DS_Store'),
        (os.path.join(build.distdir, 'branding', 'background.png'),
         '.background/background.png'),
        (os.path.join(build.distdir, 'branding', 'disk.icns'),
         '.VolumeIcon.icns'),
    ]
    volume_name = build.substs['MOZ_APP_DISPLAYNAME']
    need_signing = [
        'SQLiteWriter.app/Contents/MacOS/plugin-container.app',
        'SQLiteWriter.app/Contents/MacOS/sqlite-writer-bin',
        'SQLiteWriter.app/Contents/MacOS/pingsender',
        'SQLiteWriter.app/Contents/MacOS/*.dylib',
        'SQLiteWriter.app/Contents/MacOS/XUL',
        'SQLiteWriter.app',
    ]
    for rel_path in need_signing:
        print('Signing ' + rel_path + ' ...')
        abs_path = os.path.join(os.getcwd(), source_directory, rel_path)
        os.system('codesign --force --sign - --entitlements $ENTITLEMENTS_PATH ' + abs_path)
    dmg.create_dmg(source_directory, output_dmg, volume_name, extra_files)


def main(args):
    if len(args) != 2:
        print('Usage: make_dmg.py <source directory> <output dmg>',
              file=sys.stderr)
        return 1
    make_dmg(args[0], args[1])
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
