# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /tools/internal/Sanity/bugzilla-3-6-beaker-test-suite
#   Description: This test is for testing Red Hat Bugzilla version 3.6. 
#   It first installs the required rpms (bugzilla and mysql server) via yum, 
#   then calls the existing test files in t/ directory to test Red Hat 
#   Bugzilla code and report the related results.
#   Author: Red Hat Bugzilla Team <bugzilla-owner@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BUILT_FILES=
FILES=runtest.sh Makefile bugzilla.tar.gz
BZR_BUGZILLA_PATH="bzr://bzr.mozilla.org/bmo/3.6"

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES) 
	chmod a+x runtest.sh

clean:
	rm -f *~ $(BUILT_FILES) bugzilla.tar.gz
	rm -rf bugzilla/
	rm -rf qa/

bugzilla:
	bzr co $(BZR_BUGZILLA_PATH) bugzilla

bugzilla.tar.gz: bugzilla 
	mkdir -p bugzilla/t
	cp -pr t/* bugzilla/t
	mkdir -p bugzilla/t/config
	cp config/* bugzilla/t/config
	# FIXME: Gives error /var/www/html/bugzilla/.htaccess: ExpiresActive not allowed here
	rm bugzilla/.htaccess
	find bugzilla/ -depth -name .bzr -type d -exec rm -rf {} \;
	find bugzilla/ -depth -name .bzrignore -type f -exec rm -rf {} \;
	tar zcvf bugzilla.tar.gz bugzilla/
