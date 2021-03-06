# Figure out where we are.
TOP:=$(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
TOP:=$(patsubst %/,%,$(TOP))

# TOPDIR is the normal variable you should use, because
# if we are executing relative to the current directory
# it can be "", whereas TOP must be "." which causes
# pattern matching probles when make strips off the
# trailing "./" from paths in various places.
ifeq ($(TOP),.)
TOPDIR:=
else
TOPDIR:= $(TOP)/
endif

# Standard source directories.
BUILD_SYSTEM:= $(TOPDIR)build_system
SRC_COMPONENTS:= $(TOPDIR)components
SRC_DOCS:= $(TOPDIR)docs
SRC_HEADERS:= $(TOPDIR)headers
SRC_INTERFACES:= $(TOPDIR)interfaces
SRC_LIBRARIES:= $(TOPDIR)libraries
#SRC_MODULES:= $(TOPDIR)modules
SRC_SCRIPTS:= $(TOPDIR)scripts
SRC_SERVERS:= $(TOPDIR)servers
SRC_TOOLS:= $(TOPDIR)tools

# Standard build output directories.
OUT:= $(TOPDIR)build
OUT_DOCS:= $(OUT)/docs
OUT_EXECUTABLES:= $(OUT)/bin
OUT_HEADERS:= $(OUT)/headers
OUT_HOST_EXECUTABLES:= $(OUT)/bin
OUT_INTERMEDIATES:= $(OUT)/obj
OUT_LIBRARIES:= $(OUT)/lib
OUT_PACKAGES:= $(OUT)/packages
OUT_SCRIPTS:= $(OUT)/scripts

CLEAR_VARS:= $(BUILD_SYSTEM)/clear_vars.make
BUILD_HOST_STATIC_LIBRARY:= $(BUILD_SYSTEM)/host_static_library.make
BUILD_STATIC_LIBRARY:= $(BUILD_SYSTEM)/static_library.make
BUILD_SHARED_LIBRARY:= $(BUILD_SYSTEM)/shared_library.make
BUILD_BINDER_SHARED_LIBRARY:= $(BUILD_SYSTEM)/binder_shared_library.make
BUILD_EXECUTABLE:= $(BUILD_SYSTEM)/executable.make
BUILD_BINDER_EXECUTABLE:= $(BUILD_SYSTEM)/binder_executable.make
BUILD_HOST_EXECUTABLE:= $(BUILD_SYSTEM)/host_executable.make
BUILD_PACKAGE:= $(BUILD_SYSTEM)/package.make
BUILD_SCRIPT:= $(BUILD_SYSTEM)/script.make

# If cross-compiling, we need to distinguish between the compilers for the
# host, used for tools such as pidgen and makestrings, and the compilers for
# the target, used for everything else. If you aren't cross-compiling, these
# will be the same.

HOST_CC := $(CC)
HOST_CXX := $(CXX)
HOST_AR := $(AR)

LEX:= flex
YACC:= bison -d -v -y
PIDGEN:= $(OUT_HOST_EXECUTABLES)/pidgen
MAKESTRINGS:= $(OUT_HOST_EXECUTABLES)/makestrings
DOXYGEN:= doxygen

# Configure some options based on possible dummy targets.

# The 'pidgen' goal is special specifying that we would
# also like to build the pidgen tool -and- have the IDL
# files depend on it.  This is normally set only if the
# pidgen tool hasn't been built; if it has been built,
# we normally would prefer not to rebuild it and all
# of the interfaces generated by it.
ifeq ($(filter pidgen,$(MAKECMDGOALS)),pidgen)
PIDGEN_DEP:=$(PIDGEN)
else
ifeq ($(wildcard $(PIDGEN)),)
# Didn't explicitly ask for pidgen, but the tool doesn't
# exist so we will need to build it anyway.
PIDGEN_DEP:=$(PIDGEN)
endif
endif

# The 'nomodules' goal says to not do anything with
# modules when building and cleaning.  Only work with
# user-space code.
#NO_MODULES:= $(filter nomodules,$(MAKECMDGOALS))

# The 'debugtools' goal says to compile build tools with
# debug options.  Normally they are compiled with release
# options, even when the rest of the targets are being
# built for debugging.
DEBUG_TOOLS:= $(filter debugtools,$(MAKECMDGOALS))

# The 'showcommands' goal says to show the full command
# lines being executed, instead of a short message about
# the kind of operation being done.
SHOW_COMMANDS:= $(filter showcommands,$(MAKECMDGOALS))

DEBUG_CFLAGS:= -O0 -g -ggdb -fpermissive
RELEASE_CFLAGS:= -O3 -g0 -fpermissive

RELEASE_LDFLAGS:= -Wl,-O,1 -s

ifeq ($(DEBUG_TOOLS),)
TOOL_CFLAGS:= $(RELEASE_CFLAGS)
TOOL_LDFLAGS:= $(RELEASE_LDFLAGS)
endif

C_SYSTEM_INCLUDES:= $(SRC_HEADERS) $(OUT_HEADERS)
GLOBAL_CFLAGS:= \
	$(DEBUG_CFLAGS) \
	-fPIC \
	-DBUILD_TYPE=BUILD_TYPE_DEBUG \
	-DTARGET_PLATFORM=TARGET_PLATFORM_PALMSIM_LINUX \
	-DTARGET_HOST=TARGET_HOST_LINUX \
	-D_SUPPORTS_EXCEPTIONS=1 \
	-DVALIDATES_REGION=0 \
	-DVALIDATES_VALUE=0 \
	-DSUPPORTS_LOCK_DEBUG=1 \
	-DSUPPORTS_ATOM_DEBUG=1 \
	-D_SUPPORTS_NAMESPACE=0 \
	-DSUPPORTS_UNIX_FILE_PATH=1 \
	-DSUPPORTS_TEXT_STREAM=1 \
	-DSUPPORTS_CALL_STACK=1 \
	-DLINUX_DEMO_HACK=1 \
	-Wno-multichar

#	-D_BUILDING_SUPPORT=1
#	-g -O0

GLOBAL_IDL_INCLUDES:= $(SRC_INTERFACES)

GLOBAL_LDFLAGS:= -L$(OUT_LIBRARIES) -Wl,--no-undefined -lc -lrt -lstdc++ -ldl -lpthread

# This is the default target (see below)
.PHONY: user
user::

# Bring in standard build system definitions.
include $(BUILD_SYSTEM)/definitions.make

# Bring in all targets that need to be built.
include $(call all-makefiles-under,$(TOP))

# -------------------------------------------------------------------
	
# Alternate target: only build user space code (no modules)
.PHONY: user
user:: $(ALL_TARGETS)

MODULE_CFLAGS:= \
	$(foreach header,$(C_SYSTEM_INCLUDES),-I $(PWD)/$(header)) \
	$(foreach header,$(C_INCLUDES),-I $(PWD)/$(header))

#.PHONY: modules
#modules::
#	@$(MAKE) -C $(SRC_MODULES)/binder --no-print-directory CUSTOM_CFLAGS='$(MODULE_CFLAGS)'

#.PHONY: modules_install
#modules_install::
#	@$(MAKE) -C $(SRC_MODULES)/binder --no-print-directory CUSTOM_CFLAGS='$(MODULE_CFLAGS)' modules_install

#.PHONY: modules_clean
#modules_clean::
#	@$(MAKE) -C $(SRC_MODULES)/binder --no-print-directory CUSTOM_CFLAGS='$(MODULE_CFLAGS)' clean

#.PHONY: loadmodules
#loadmodules::
#	@$(MAKE) -C $(SRC_MODULES)/binder --no-print-directory CUSTOM_CFLAGS='$(MODULE_CFLAGS)' loadmodules

#.PHONY: unloadmodules
#unloadmodules::
#	@$(MAKE) -C $(SRC_MODULES)/binder --no-print-directory CUSTOM_CFLAGS='$(MODULE_CFLAGS)' unloadmodules

.PHONY: test
test:: user
	(. $(OUT_SCRIPTS)/setup_env.sh; smooved -e $(PWD)/$(OUT_SCRIPTS)/test.bsh)

.PHONY: runshell
runshell:: user
	(. $(OUT_SCRIPTS)/setup_env.sh; smooved -s $(PWD)/$(OUT_SCRIPTS)/boot_script.bsh)

# Build the entire world!
.PHONY: all
all:: user
#ifeq ($(NO_MODULES),)
#all:: loadmodules
#endif

.PHONY: clean
clean::
#ifeq ($(NO_MODULES),)
#	@$(MAKE) -C $(SRC_MODULES)/binder clean
#endif
	@rm -rf $(ALL_TARGETS)
	@rm -rf $(ALL_INTERMEDIATES)
	@echo "All outputs removed."

#$(foreach file,$(ALL_TARGETS) $(ALL_INTERMEDIATES),$(shell rm -f $file))

.PHONY: realclean
realclean::
#ifeq ($(NO_MODULES),)
#	@$(MAKE) -C $(SRC_MODULES)/binder clean
#endif
	@rm -rf build
	@echo "Entire build directory removed."

.PHONY: help
help::
	@echo "Top-level targets:"
	@echo "  user: (default) Build all user-space code into build/"
#	@echo "  modules: Build all kernel modules"
#	@echo "  loadmodules: Build modules and load into kernel"
	@echo "  all: Build user, modules, loadmodules, test"
	@echo "  interfaces: Build all .h/cpp files from IDLs"
	@echo "  pidgen: Build the pidgen tool and rebuild any needed interfaces"
	@echo "  docs: Build documentation from sources.  Requires Doxygen."
	@echo
	@echo "Testing targets:"
	@echo "  test: Run smooved with a basic test script"
	@echo "  runshell: Run smooved with an interactive BinderShell session"
	@echo
	@echo "Cleanup targets:"
#	@echo "  unloadmodules: Unload modules from kernel"
	@echo "  clean: Remove all built files and kernel modules"
	@echo "  cleandocs: Remove all generated documentation"
	@echo "  realclean: Remove everything under build/ and kernel modules"
	@echo
	@echo "Modifier targets:"
#	@echo "  nomodules: Don't do anything with kernel modules"
	@echo "  debugtools: Use debug options when compiling build tools"
	@echo "  showcommands: Show raw command lines being executed"
	@echo
	@echo "Available sub-targets:"
	@echo "  $(ALL_TARGET_NAMES)"
	
#.PHONY: nomodules
#nomodules::
#	@echo >/dev/null

.PHONY: debugtools
debugtools::
	@echo >/dev/null

.PHONY: showcommands
showcommands::
	@echo >/dev/null
